function PawCareAdminDashboardCtrl($scope, $http, $q) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.loading = false;
  vm.error = false;
  vm.message = '';
  vm.preset = 'all';
  vm.filter = { from: '', to: '' };

  vm.kpi = {
    totalUsers: 0, customers: 0, totalProviders: 0,
    pendingProviders: 0, approvedProviders: 0,
    totalBookings: 0, completedBookings: 0, activeBookings: 0, cancelledBookings: 0,
    reviewCount: 0, avgRating: '0.0', openComplaints: 0, disputes: 0, openReports: 0
  };
  vm.finance = {};
  vm.bookingSeries = [];
  vm.statusBreakdown = [];
  vm.roleBreakdown = [];
  vm.providerBreakdown = [];
  vm.workQueue = [];
  vm.totalWorkCount = 0;
  vm.recentBookings = [];

  var allUsers = [];
  var allProviders = [];
  var allBookings = [];
  var allReviews = [];
  var allComplaints = [];
  var financeData = {};
  var openReportsTotal = 0;

  vm.money = function (v) { return U.formatMoney ? U.formatMoney(v) : (Number(v || 0).toLocaleString('vi-VN') + ' ₫'); };
  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : s; };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };
  vm.go = function (token) { if (U.navigate) U.navigate(token); };

  function safeGet(url, params) {
    return $http.get(url, params ? { params: params } : undefined).then(
      function (r) { return { ok: true, data: r.data }; },
      function (r) { return { ok: false, response: r }; }
    );
  }

  function inDateRange(val) {
    if (!vm.filter.from && !vm.filter.to) return true;
    var key = U.toDateKey ? U.toDateKey(val) : '';
    if (!key) return false;
    if (vm.filter.from && key < vm.filter.from) return false;
    if (vm.filter.to && key > vm.filter.to) return false;
    return true;
  }

  function recompute() {
    var customers = allUsers.filter(function (u) { return u.role_code === 'CUSTOMER'; }).length;
    var providerUsers = allUsers.filter(function (u) { return u.role_code === 'PROVIDER'; }).length;
    var admins = allUsers.filter(function (u) { return u.role_code === 'ADMIN'; }).length;

    var pendingProv = allProviders.filter(function (p) { return p.status === 'PENDING' || p.status === 'NEED_MORE_INFO'; }).length;
    var approvedProv = allProviders.filter(function (p) { return p.status === 'APPROVED'; }).length;

    var filteredBookings = allBookings.filter(function (b) {
      return inDateRange(b.created_at || b.booking_start);
    });

    var completedB = 0, activeB = 0, cancelledB = 0;
    var statusCounts = {};
    var dailyMap = {};

    filteredBookings.forEach(function (b) {
      var st = String(b.status || 'UNKNOWN').toUpperCase();
      statusCounts[st] = (statusCounts[st] || 0) + 1;
      if (st === 'COMPLETED') completedB++;
      else if (st === 'CANCELLED' || st === 'REJECTED') cancelledB++;
      else activeB++;

      var dKey = U.toDateKey ? U.toDateKey(b.booking_start || b.created_at) : '';
      if (dKey) {
        if (!dailyMap[dKey]) dailyMap[dKey] = { fullDate: dKey, count: 0, amount: 0 };
        dailyMap[dKey].count += 1;
        dailyMap[dKey].amount += Number(b.estimated_price || 0);
      }
    });

    var ratedSum = 0;
    allReviews.forEach(function (rv) { ratedSum += Number(rv.rating || 0); });
    var avg = allReviews.length ? (ratedSum / allReviews.length).toFixed(1) : '0.0';

    var openComp = allComplaints.filter(function (c) { return c.status === 'OPEN' || c.status === 'IN_PROGRESS'; }).length;
    var finSummary = (financeData && financeData.summary) || {};
    var finDisputes = (financeData && financeData.disputes) || [];
    var pendingWithdrawals = Number(finSummary.pending_count || 0);

    vm.kpi = {
      totalUsers: allUsers.length,
      customers: customers,
      totalProviders: allProviders.length || providerUsers,
      pendingProviders: pendingProv,
      approvedProviders: approvedProv,
      totalBookings: filteredBookings.length,
      completedBookings: completedB,
      activeBookings: activeB,
      cancelledBookings: cancelledB,
      reviewCount: allReviews.length,
      avgRating: avg,
      openComplaints: openComp,
      disputes: finDisputes.length,
      openReports: openReportsTotal
    };

    vm.finance = finSummary;

    // Booking series (chronological, max 12 real dates)
    var sortedKeys = Object.keys(dailyMap).sort().slice(-12);
    var maxCount = sortedKeys.reduce(function (m, k) { return Math.max(m, dailyMap[k].count); }, 1);
    vm.bookingSeries = sortedKeys.map(function (k) {
      var pts = k.split('-');
      return {
        fullDate: pts[2] + '/' + pts[1] + '/' + pts[0],
        label: pts[2] + '/' + pts[1],
        count: dailyMap[k].count,
        amount: dailyMap[k].amount,
        pct: Math.max(6, Math.round((dailyMap[k].count / maxCount) * 100))
      };
    });

    // Status breakdown
    var toneColors = {
      success: '#10B981',
      warning: '#F59E0B',
      info: '#167CB7',
      danger: '#E11D48',
      neutral: '#64748B'
    };
    var totalForPct = Math.max(filteredBookings.length, 1);
    vm.statusBreakdown = Object.keys(statusCounts).sort(function (a, b) {
      return statusCounts[b] - statusCounts[a];
    }).map(function (st) {
      var tone = U.statusTone ? U.statusTone(st) : 'neutral';
      return {
        status: st,
        count: statusCounts[st],
        pct: Math.round((statusCounts[st] / totalForPct) * 100),
        color: toneColors[tone] || '#64748B'
      };
    });

    // Role breakdown
    var totalUsersSafe = Math.max(allUsers.length, 1);
    vm.roleBreakdown = [
      { label: 'Khách hàng (CUSTOMER)', count: customers, pct: Math.round((customers / totalUsersSafe) * 100), color: '#167CB7' },
      { label: 'Đối tác (PROVIDER)', count: providerUsers, pct: Math.round((providerUsers / totalUsersSafe) * 100), color: '#0F766E' },
      { label: 'Quản trị viên (ADMIN)', count: admins, pct: Math.round((admins / totalUsersSafe) * 100), color: '#0B3557' }
    ].filter(function (r) { return r.count > 0 || allUsers.length === 0; });

    // Provider status breakdown
    var provCounts = {};
    allProviders.forEach(function (p) {
      var st = String(p.status || 'PENDING').toUpperCase();
      provCounts[st] = (provCounts[st] || 0) + 1;
    });
    vm.providerBreakdown = Object.keys(provCounts).map(function (st) {
      return { status: st, count: provCounts[st] };
    });

    // Action Queue
    var queue = [];
    if (pendingProv > 0) {
      queue.push({
        page: 'providers',
        title: 'Hồ sơ Provider chờ xét duyệt',
        subtitle: 'Kiểm tra thông tin cơ sở mới đăng ký và phê duyệt hoạt động',
        countLabel: pendingProv + ' hồ sơ',
        badgeClass: 'pc-badge--warning'
      });
    }
    if (pendingWithdrawals > 0) {
      queue.push({
        page: 'finance',
        title: 'Yêu cầu rút tiền chờ chuyển khoản',
        subtitle: 'Tổng giá trị đang chờ duyệt: ' + vm.money(finSummary.pending_amount),
        countLabel: pendingWithdrawals + ' lệnh rút',
        badgeClass: 'pc-badge--warning'
      });
    }
    if (finDisputes.length > 0) {
      queue.push({
        page: 'disputes',
        title: 'Tranh chấp Booking đang giữ Escrow',
        subtitle: 'Cần Admin xem lịch sử và quyết định hoàn tiền hoặc giải ngân',
        countLabel: finDisputes.length + ' tranh chấp',
        badgeClass: 'pc-badge--danger'
      });
    }
    if (openComp > 0) {
      queue.push({
        page: 'complaints',
        title: 'Khiếu nại khách hàng cần phản hồi',
        subtitle: 'Theo dõi và cập nhật tiến độ giải quyết khiếu nại',
        countLabel: openComp + ' khiếu nại',
        badgeClass: 'pc-badge--info'
      });
    }
    if (openReportsTotal > 0) {
      queue.push({
        page: 'conversation-reports',
        title: 'Báo cáo hội thoại chờ kiểm duyệt',
        subtitle: 'Các hội thoại bị báo cáo cần rà soát nội dung và xử lý',
        countLabel: openReportsTotal + ' report',
        badgeClass: 'pc-badge--warning'
      });
    }
    vm.workQueue = queue;
    vm.totalWorkCount = pendingProv + pendingWithdrawals + finDisputes.length + openComp + openReportsTotal;

    // Recent bookings
    vm.recentBookings = filteredBookings.slice(0, 6);
  }

  vm.applyPreset = function (preset) {
    vm.preset = preset;
    if (U.presetDateRange) {
      vm.filter = U.presetDateRange(preset);
    }
    vm.load();
  };

  vm.load = function () {
    vm.loading = true;
    vm.error = false;
    vm.message = '';

    var finParams = {};
    if (vm.filter.from) finParams.from = vm.filter.from;
    if (vm.filter.to) finParams.to = vm.filter.to;

    $q.all([
      safeGet('/bonita/API/extension/users', { c: 100 }),
      safeGet('/bonita/API/extension/providers', { c: 100 }),
      safeGet('/bonita/API/extension/bookings', { c: 100 }),
      safeGet('/bonita/API/extension/reviews', { c: 100 }),
      safeGet('/bonita/API/extension/complaints', { c: 100 }),
      safeGet('/bonita/API/extension/finance', finParams),
      safeGet('/bonita/API/extension/conversation-reports', { status: 'OPEN', page: 0, size: 1 })
    ]).then(function (res) {
      var anyOk = res.some(function (x) { return x.ok; });
      if (!anyOk) {
        vm.error = true;
        vm.message = U.errorText ? U.errorText(res[0].response, 'Không thể kết nối API quản trị.') : 'Không thể tải số liệu.';
        return;
      }
      allUsers = res[0].ok && res[0].data && res[0].data.data ? res[0].data.data : [];
      allProviders = res[1].ok && res[1].data && res[1].data.data ? res[1].data.data : [];
      allBookings = res[2].ok && res[2].data && res[2].data.data ? res[2].data.data : [];
      allReviews = res[3].ok && res[3].data && res[3].data.data ? res[3].data.data : [];
      allComplaints = res[4].ok && res[4].data && res[4].data.data ? res[4].data.data : [];
      financeData = res[5].ok && res[5].data ? res[5].data : {};
      openReportsTotal = res[6].ok && res[6].data ? Number(res[6].data.totalElements || 0) : 0;

      recompute();
    }).finally(function () {
      vm.loading = false;
    });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
