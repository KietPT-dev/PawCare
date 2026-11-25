function PawCareAdminProvidersCtrl($scope, $http) {
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
  vm.detailTarget = null;
  vm.decisionTarget = null;
  vm.decisionStatus = '';
  vm.rejectionReason = '';
  vm.stats = { total: 0, pending: 0, approved: 0, rejected: 0 };

  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : s; };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };

  function err(r) {
    vm.error = true;
    vm.message = U.errorText ? U.errorText(r, 'Không thể tải Provider.') : 'Không thể tải Provider.';
  }

  function computeStats() {
    var pending = 0, approved = 0, rejected = 0;
    vm.rows.forEach(function (p) {
      if (p.status === 'PENDING' || p.status === 'NEED_MORE_INFO') pending++;
      else if (p.status === 'APPROVED') approved++;
      else if (p.status === 'REJECTED' || p.status === 'SUSPENDED') rejected++;
    });
    vm.stats = { total: vm.rows.length, pending: pending, approved: approved, rejected: rejected };
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
    vm.filtered = vm.rows.filter(function (p) {
      if (vm.statusFilter) {
        if (vm.statusFilter === 'PENDING' && p.status !== 'PENDING' && p.status !== 'NEED_MORE_INFO') return false;
        if (vm.statusFilter === 'REJECTED' && p.status !== 'REJECTED' && p.status !== 'SUSPENDED') return false;
        if (vm.statusFilter === 'APPROVED' && p.status !== 'APPROVED') return false;
      }
      if (q) {
        var hay = [p.id, p.name, p.email, p.phone, p.address, p.service_area].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
    vm.updatePage();
  };

  vm.load = function () {
    vm.loading = true;
    $http.get('/bonita/API/extension/providers', { params: { c: 100 } }).then(function (r) {
      vm.error = false;
      vm.rows = (r.data && r.data.data) || [];
      computeStats();
      vm.applyFilter(false);
    }, err).finally(function () { vm.loading = false; });
  };

  vm.openDetail = function (p) {
    vm.detailTarget = p;
  };

  vm.openApprove = function (p) {
    vm.detailTarget = null;
    vm.decisionTarget = p;
    vm.decisionStatus = 'APPROVED';
    vm.rejectionReason = '';
  };

  vm.openReject = function (p) {
    vm.detailTarget = null;
    vm.decisionTarget = p;
    vm.decisionStatus = 'REJECTED';
    vm.rejectionReason = p.rejection_reason || '';
  };

  vm.confirmDecision = function () {
    if (!vm.decisionTarget) return;
    var body = { id: vm.decisionTarget.id, status: vm.decisionStatus };
    if (vm.decisionStatus === 'REJECTED') {
      body.rejection_reason = vm.rejectionReason || '';
    }
    vm.saving = true;
    $http.put('/bonita/API/extension/providers', body).then(function () {
      vm.error = false;
      vm.message = vm.decisionStatus === 'APPROVED'
        ? 'Đã duyệt Provider ' + vm.decisionTarget.name + '.'
        : 'Đã từ chối hồ sơ Provider ' + vm.decisionTarget.name + '.';
      vm.decisionTarget = null;
      vm.load();
      try { if (window.parent && window.parent !== window) window.parent.postMessage(JSON.stringify({ message: 'pawcareBadgesDirty' }), '*'); } catch (e) {}
    }, err).finally(function () { vm.saving = false; });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
