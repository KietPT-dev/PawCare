function PawCareAdminComplaintsCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.filtered = [];
  vm.paged = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.query = '';
  vm.statusFilter = '';
  vm.page = 0;
  vm.loading = false;
  vm.saving = false;
  vm.message = '';
  vm.error = false;
  vm.selected = null;
  vm.draftResponse = '';
  vm.stats = { total: 0, open: 0, inProgress: 0, resolved: 0, rejected: 0 };

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
    vm.message = U.errorText ? U.errorText(r, 'Không thể tải danh sách khiếu nại.') : 'Không thể tải danh sách khiếu nại.';
  }

  function computeStats() {
    var open = 0, inProgress = 0, resolved = 0, rejected = 0;
    vm.rows.forEach(function (c) {
      var st = String(c.status || '').toUpperCase();
      if (st === 'OPEN') open++;
      else if (st === 'IN_PROGRESS') inProgress++;
      else if (st === 'RESOLVED') resolved++;
      else if (st === 'REJECTED') rejected++;
    });
    vm.stats = {
      total: vm.rows.length,
      open: open,
      inProgress: inProgress,
      resolved: resolved,
      rejected: rejected
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
    vm.filtered = vm.rows.filter(function (c) {
      if (vm.statusFilter && String(c.status || '').toUpperCase() !== vm.statusFilter) return false;
      if (q) {
        var hay = [
          c.id, c.booking_id, c.customer_name, c.customer_email,
          c.provider_name, c.content, c.admin_response, c.status
        ].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
    vm.updatePage();
  };

  vm.clearFilters = function () {
    vm.query = '';
    vm.statusFilter = '';
    vm.applyFilter(true);
  };

  vm.load = function () {
    vm.loading = true;
    $http.get('/bonita/API/extension/complaints', { params: { c: 100 } }).then(function (r) {
      vm.error = false;
      vm.rows = (r.data && r.data.data) || [];
      vm.rows.forEach(function (c) { c.admin_response = c.admin_response || ''; });
      computeStats();
      vm.applyFilter(false);
    }, err).finally(function () { vm.loading = false; });
  };

  vm.openDetail = function (c) {
    vm.selected = c;
    vm.draftResponse = c.admin_response || '';
  };

  vm.closeDetail = function () {
    vm.selected = null;
    vm.draftResponse = '';
  };

  vm.save = function (status) {
    if (!vm.selected) return;
    vm.saving = true;
    var targetId = vm.selected.id;
    $http.put('/bonita/API/extension/complaints', {
      id: targetId,
      status: status,
      admin_response: vm.draftResponse || ''
    }).then(function () {
      vm.error = false;
      vm.message = 'Đã cập nhật khiếu nại #' + targetId + ' sang ' + vm.statusLabel(status) + '.';
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
