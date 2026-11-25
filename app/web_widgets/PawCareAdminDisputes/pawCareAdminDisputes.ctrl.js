function PawCareAdminDisputesCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.histories = [];
  vm.filtered = [];
  vm.paged = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.query = '';
  vm.scopeFilter = '';
  vm.page = 0;
  vm.loading = false;
  vm.saving = false;
  vm.message = '';
  vm.error = false;
  vm.selected = null;
  vm.adminNote = '';
  vm.pendingAction = '';
  vm.stats = { total: 0, disputed: 0, activeComplaints: 0, frozenEscrow: 0 };

  vm.money = function (v) { return U.formatMoney ? U.formatMoney(v) : (Number(v || 0).toLocaleString('vi-VN') + ' ₫'); };
  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : (s || '—'); };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };

  function notifyBadgesDirty() {
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(JSON.stringify({ message: 'pawcareBadgesDirty' }), '*');
      }
    } catch (e) {}
  }

  function err(r) {
    vm.error = true;
    vm.message = U.errorText ? U.errorText(r, 'Không thể tải tranh chấp.') : 'Không thể tải tranh chấp.';
  }

  function computeStats() {
    var disputed = 0, activeComplaints = 0, frozenEscrow = 0;
    vm.rows.forEach(function (d) {
      var bst = String(d.booking_status || '').toUpperCase();
      var cst = String(d.complaint_status || '').toUpperCase();
      if (bst === 'DISPUTED') {
        disputed++;
        frozenEscrow += Number(d.escrow_amount || d.estimated_price || 0);
      }
      if (cst === 'OPEN' || cst === 'IN_PROGRESS') {
        activeComplaints++;
      }
    });
    vm.stats = {
      total: vm.rows.length,
      disputed: disputed,
      activeComplaints: activeComplaints,
      frozenEscrow: frozenEscrow
    };
  }

  vm.updatePage = function () {
    vm.paged = U.paginate ? U.paginate(vm.filtered, vm.page, 15) : {
      items: vm.filtered, page: 0, size: 15, total: vm.filtered.length, totalPages: 1, from: 1, to: vm.filtered.length
    };
    vm.page = vm.paged.page;
  };

  vm.applyFilter = function (resetPage) {
    if (resetPage) vm.page = 0;
    var q = (vm.query || '').toLowerCase().trim();
    vm.filtered = vm.rows.filter(function (d) {
      var bst = String(d.booking_status || '').toUpperCase();
      if (vm.scopeFilter === 'DISPUTED' && bst !== 'DISPUTED') return false;
      if (vm.scopeFilter === 'OTHER' && bst === 'DISPUTED') return false;
      if (q) {
        var hay = [
          d.booking_id, d.complaint_id, d.customer_name, d.provider_name,
          d.content, d.booking_status, d.complaint_status, d.escrow_status
        ].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
    vm.updatePage();
  };

  vm.clearFilters = function () {
    vm.query = '';
    vm.scopeFilter = '';
    vm.applyFilter(true);
  };

  vm.history = function (bookingId) {
    return vm.histories.filter(function (h) {
      return String(h.booking_id) === String(bookingId);
    });
  };

  vm.load = function () {
    vm.loading = true;
    $http.get('/bonita/API/extension/finance?status=PENDING').then(function (r) {
      vm.error = false;
      vm.rows = (r.data && r.data.disputes) || [];
      vm.histories = (r.data && r.data.histories) || [];
      computeStats();
      vm.applyFilter(false);
    }, err).finally(function () { vm.loading = false; });
  };

  vm.openDetail = function (d) {
    vm.selected = d;
    vm.adminNote = d.admin_response || '';
    vm.pendingAction = '';
  };

  vm.closeDetail = function () {
    vm.selected = null;
    vm.adminNote = '';
    vm.pendingAction = '';
  };

  vm.chooseAction = function (action) {
    vm.pendingAction = action;
  };

  vm.cancelAction = function () {
    vm.pendingAction = '';
  };

  vm.executeResolve = function () {
    if (!vm.selected || !vm.pendingAction) return;
    vm.saving = true;
    var bookingId = vm.selected.booking_id;
    $http.post('/bonita/API/extension/finance', {
      complaint_id: vm.selected.complaint_id,
      action: vm.pendingAction,
      admin_note: vm.adminNote || ''
    }).then(function () {
      vm.error = false;
      vm.message = 'Đã xử lý tranh chấp Booking #' + bookingId + '. Số dư ví, ledger và trạng thái booking đã được cập nhật.';
      vm.closeDetail();
      vm.load();
      notifyBadgesDirty();
    }, err).finally(function () { vm.saving = false; });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
