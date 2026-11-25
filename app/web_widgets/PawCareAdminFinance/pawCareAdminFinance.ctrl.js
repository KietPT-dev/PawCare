function PawCareAdminFinanceCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.data = { summary: {}, ledger: [], withdrawals: [], disputes: [], histories: [], bookingStatuses: [] };
  vm.filter = { type: '', status: 'PENDING', from: '', to: '' };
  vm.preset = 'all';
  vm.chartTab = 'timeline';
  vm.loading = false;
  vm.message = '';
  vm.error = false;
  vm.selected = null;
  vm.selectedLedger = null;
  vm.note = '';

  vm.withdrawalQuery = '';
  vm.ledgerQuery = '';
  vm.wPage = 0;
  vm.lPage = 0;

  vm.filteredWithdrawals = [];
  vm.pagedWithdrawals = { items: [], page: 0, size: 10, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.filteredLedger = [];
  vm.pagedLedger = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.ledgerSeries = [];
  vm.flowBars = [];
  vm.donutSegments = [];
  vm.totalStatusBookings = 0;

  vm.money = function (v) { return U.formatMoney ? U.formatMoney(v) : (Number(v || 0).toLocaleString('vi-VN') + ' ₫'); };
  vm.compactMoney = function (v) { return U.formatCompactMoney ? U.formatCompactMoney(v) : vm.money(v); };
  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : s; };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };
  vm.errorText = function (r) { return U.errorText ? U.errorText(r, 'Không thể tải dữ liệu tài chính.') : 'Không thể tải dữ liệu.'; };

  function buildCharts() {
    // 1. Ledger daily trend (only actual COMMISSION_FEE & PROVIDER_PAYOUT days)
    var ledger = vm.data.ledger || [];
    var dayMap = {};
    ledger.forEach(function (t) {
      var dKey = U.toDateKey ? U.toDateKey(t.created_at) : '';
      if (!dKey) return;
      if (!dayMap[dKey]) dayMap[dKey] = { fullDate: dKey, payout: 0, fee: 0 };
      var amt = Math.max(0, Number(t.amount || 0));
      if (t.type === 'PROVIDER_PAYOUT') dayMap[dKey].payout += amt;
      else if (t.type === 'COMMISSION_FEE') dayMap[dKey].fee += amt;
    });
    var keys = Object.keys(dayMap).filter(function (k) {
      return dayMap[k].payout > 0 || dayMap[k].fee > 0;
    }).sort().slice(-12);

    var maxDayVal = keys.reduce(function (m, k) {
      return Math.max(m, dayMap[k].payout, dayMap[k].fee);
    }, 1);

    vm.ledgerSeries = keys.map(function (k) {
      var pts = k.split('-');
      return {
        fullDate: pts[2] + '/' + pts[1] + '/' + pts[0],
        label: pts[2] + '/' + pts[1],
        payout: dayMap[k].payout,
        fee: dayMap[k].fee,
        payoutPct: dayMap[k].payout > 0 ? Math.max(6, Math.round((dayMap[k].payout / maxDayVal) * 100)) : 0,
        feePct: dayMap[k].fee > 0 ? Math.max(6, Math.round((dayMap[k].fee / maxDayVal) * 100)) : 0
      };
    });

    // 2. Flow Comparison
    var s = vm.data.summary || {};
    var flows = [
      { label: 'GMV (Tổng giá trị Booking)', amount: Number(s.gmv || 0), color: '#167CB7' },
      { label: 'Đã payout cho Provider', amount: Number(s.provider_payout || 0), color: '#0F766E' },
      { label: 'Escrow đang khóa bảo chứng', amount: Number(s.escrow_held || 0), color: '#F59E0B' },
      { label: 'Phí nền tảng (10%)', amount: Number(s.commission_revenue || 0), color: '#10B981' },
      { label: 'Tổng ví Provider', amount: Number(s.provider_wallets || 0), color: '#0B3557' },
      { label: 'Tổng ví User', amount: Number(s.user_wallets || 0), color: '#0891B2' },
      { label: 'Rút tiền đã duyệt', amount: Number(s.approved_amount || 0), color: '#64748B' }
    ];
    var maxFlow = flows.reduce(function (m, f) { return Math.max(m, f.amount); }, 1);
    vm.flowBars = flows.map(function (f) {
      return {
        label: f.label,
        amount: f.amount,
        color: f.color,
        pct: f.amount > 0 ? Math.max(3, Math.round((f.amount / maxFlow) * 100)) : 0
      };
    });

    // 3. Booking Statuses Donut
    var statuses = (vm.data.bookingStatuses || []).slice().sort(function (a, b) {
      return Number(b.booking_count || 0) - Number(a.booking_count || 0);
    });
    var total = statuses.reduce(function (sum, item) { return sum + Number(item.booking_count || 0); }, 0);
    vm.totalStatusBookings = total;

    var toneColors = { success: '#10B981', warning: '#F59E0B', info: '#167CB7', danger: '#E11D48', neutral: '#64748B' };
    var circumference = 2 * Math.PI * 42;
    var accOffset = 0;

    vm.donutSegments = total > 0 ? statuses.map(function (st) {
      var cnt = Number(st.booking_count || 0);
      var ratio = cnt / total;
      var segLen = Math.max(2, ratio * circumference);
      var tone = U.statusTone ? U.statusTone(st.status) : 'neutral';
      var seg = {
        status: st.status,
        booking_count: cnt,
        pct: Math.round(ratio * 100),
        color: toneColors[tone] || '#64748B',
        dashArray: segLen.toFixed(2) + ' ' + circumference.toFixed(2),
        dashOffset: (-accOffset).toFixed(2)
      };
      accOffset += segLen;
      return seg;
    }) : [];
  }

  vm.updatePages = function () {
    var wq = (vm.withdrawalQuery || '').toLowerCase().trim();
    vm.filteredWithdrawals = (vm.data.withdrawals || []).filter(function (w) {
      if (!wq) return true;
      return [w.id, w.bonita_case_id, w.owner_name, w.bank_name, w.bank_account_no, w.bank_account_name]
        .join(' ').toLowerCase().indexOf(wq) !== -1;
    });
    vm.pagedWithdrawals = U.paginate ? U.paginate(vm.filteredWithdrawals, vm.wPage, 10) : {
      items: vm.filteredWithdrawals, page: 0, size: 10, total: vm.filteredWithdrawals.length, totalPages: 1, from: 1, to: vm.filteredWithdrawals.length
    };
    vm.wPage = vm.pagedWithdrawals.page;

    var lq = (vm.ledgerQuery || '').toLowerCase().trim();
    vm.filteredLedger = (vm.data.ledger || []).filter(function (t) {
      if (!lq) return true;
      return [t.id, t.booking_id, t.owner_name, t.type, t.description]
        .join(' ').toLowerCase().indexOf(lq) !== -1;
    });
    vm.pagedLedger = U.paginate ? U.paginate(vm.filteredLedger, vm.lPage, 15) : {
      items: vm.filteredLedger, page: 0, size: 15, total: vm.filteredLedger.length, totalPages: 1, from: 1, to: vm.filteredLedger.length
    };
    vm.lPage = vm.pagedLedger.page;
  };

  $scope.$watchGroup(['ctrl.withdrawalQuery', 'ctrl.ledgerQuery'], function () {
    vm.updatePages();
  });

  vm.applyPreset = function (preset) {
    vm.preset = preset;
    if (U.presetDateRange) {
      var range = U.presetDateRange(preset);
      vm.filter.from = range.from;
      vm.filter.to = range.to;
    }
    vm.load();
  };

  vm.load = function (keepMessage) {
    var q = [];
    ['type', 'status', 'from', 'to'].forEach(function (k) {
      if (vm.filter[k]) q.push(k + '=' + encodeURIComponent(vm.filter[k]));
    });
    vm.loading = true;
    return $http.get('/bonita/API/extension/finance' + (q.length ? '?' + q.join('&') : ''))
      .then(function (r) {
        vm.error = false;
        if (!keepMessage) vm.message = '';
        vm.data = r.data || vm.data;
        vm.wPage = 0;
        vm.lPage = 0;
        buildCharts();
        vm.updatePages();
        return r.data;
      }, function (r) {
        vm.error = true;
        vm.message = vm.errorText(r);
      })
      .finally(function () { vm.loading = false; });
  };

  vm.refresh = function () { vm.load(); };

  vm.open = function (w) {
    vm.selected = w;
    vm.note = w.admin_note || '';
    vm.pendingDecision = '';
    vm.saving = false;
  };

  vm.chooseDecision = function (decision) {
    vm.pendingDecision = decision;
  };

  vm.cancelDecision = function () {
    vm.pendingDecision = '';
  };

  vm.decide = function (decision) {
    var targetDecision = decision || vm.pendingDecision;
    if (!vm.selected || !targetDecision) return;
    vm.saving = true;
    $http.put('/bonita/API/extension/finance', {
      id: vm.selected.id,
      decision: targetDecision,
      admin_note: vm.note
    }).then(function () {
      vm.error = false;
      vm.message = targetDecision === 'APPROVED' ? 'Đã xác nhận chuyển khoản.' : 'Đã từ chối và hoàn tiền vào ví.';
      vm.selected = null;
      vm.pendingDecision = '';
      vm.load(true);
      try { if (window.parent && window.parent !== window) window.parent.postMessage(JSON.stringify({ message: 'pawcareBadgesDirty' }), '*'); } catch (e) {}
    }, function (r) {
      vm.error = true;
      vm.message = vm.errorText(r);
    }).finally(function () { vm.saving = false; });
  };

  vm.history = function (bookingId) {
    return (vm.data.histories || []).filter(function (x) {
      return String(x.booking_id) === String(bookingId);
    });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
