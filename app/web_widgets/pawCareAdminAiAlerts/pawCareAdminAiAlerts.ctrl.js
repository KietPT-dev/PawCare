function PawCareAdminAiAlertsCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.page = 0;
  vm.size = 20;
  vm.hasMore = false;
  vm.filter = { riskLevel: '', reviewStatus: '', type: '' };
  vm.loading = false;
  vm.detailLoading = false;
  vm.saving = false;
  vm.message = '';
  vm.error = false;
  vm.detailError = '';
  vm.selected = null;
  vm.selectedDetail = null;
  vm.safeFeatures = [];
  vm.reviewerNote = '';
  vm.pendingDecision = '';
  vm.stats = { total: 0, open: 0, high: 0, reviewed: 0 };

  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : (s || '—'); };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };
  vm.safeRef = function (t, id) { return U.safeAiRef ? U.safeAiRef(t, id) : ((t || 'REF') + '-#' + (id || '—')); };
  vm.go = function (token) { if (U.navigate) U.navigate(token); };

  vm.formatScore = function (val) {
    if (val === null || val === undefined || val === '') return '—';
    var n = Number(val);
    return isNaN(n) ? '—' : n.toFixed(4);
  };

  vm.scorePercent = function (val) {
    var n = Number(val);
    if (isNaN(n)) return 0;
    return Math.max(4, Math.min(100, Math.round(n * 100)));
  };

  vm.scoreBarColor = function (level) {
    var k = String(level || '').toUpperCase();
    if (k === 'HIGH') return '#E11D48';
    if (k === 'MEDIUM') return '#F59E0B';
    return '#10B981';
  };

  function notifyBadgesDirty() {
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(JSON.stringify({ message: 'pawcareBadgesDirty' }), '*');
      }
    } catch (e) {}
  }

  function errText(r, fallback) {
    return U.errorText ? U.errorText(r, fallback) : (fallback || 'Không thể tải dữ liệu AI.');
  }

  function computeStats() {
    var open = 0, high = 0, reviewed = 0;
    vm.rows.forEach(function (item) {
      var rst = String(item.review_status || '').toUpperCase();
      var lvl = String(item.risk_level || '').toUpperCase();
      if (rst === 'OPEN') open++;
      if (rst === 'REVIEWED' || rst === 'DISMISSED') reviewed++;
      if (lvl === 'HIGH') high++;
    });
    vm.stats = {
      total: vm.rows.length,
      open: open,
      high: high,
      reviewed: reviewed
    };
  }

  vm.load = function (pageIndex, keepMessage) {
    if (typeof pageIndex === 'number' && pageIndex >= 0) {
      vm.page = pageIndex;
    }
    vm.loading = true;
    var params = { page: vm.page, size: Number(vm.size) || 20 };
    if (vm.filter.riskLevel) params.riskLevel = vm.filter.riskLevel;
    if (vm.filter.reviewStatus) params.reviewStatus = vm.filter.reviewStatus;
    if (vm.filter.type) params.type = vm.filter.type;

    return $http.get('/api/v1/admin/ai/risk-scores', {
      params: params,
      withCredentials: true
    }).then(function (r) {
      var d = r.data || {};
      vm.error = false;
      if (!keepMessage) vm.message = '';
      vm.rows = Array.isArray(d.items) ? d.items : (Array.isArray(d) ? d : []);
      vm.hasMore = vm.rows.length >= params.size;
      computeStats();
    }, function (r) {
      vm.error = true;
      vm.rows = [];
      vm.hasMore = false;
      computeStats();
      vm.message = errText(r, 'Không thể tải danh sách cảnh báo AI.');
    }).finally(function () { vm.loading = false; });
  };

  vm.setRiskLevel = function (level) {
    vm.filter.riskLevel = level;
    vm.load(0);
  };

  vm.clearFilters = function () {
    vm.filter = { riskLevel: '', reviewStatus: '', type: '' };
    vm.load(0);
  };

  vm.prevPage = function () {
    if (vm.page > 0) vm.load(vm.page - 1);
  };

  vm.nextPage = function () {
    if (vm.hasMore) vm.load(vm.page + 1);
  };

  vm.loadDetail = function (id) {
    if (!id) return;
    vm.detailLoading = true;
    vm.detailError = '';
    vm.selectedDetail = null;
    vm.safeFeatures = [];
    $http.get('/api/v1/admin/ai/risk-scores/' + encodeURIComponent(id), {
      withCredentials: true
    }).then(function (r) {
      var d = r.data || {};
      vm.selectedDetail = d;
      vm.reviewerNote = d.reviewer_note || '';
      vm.safeFeatures = U.safeRiskFeatures ? U.safeRiskFeatures(d.feature_snapshot) : [];
    }, function (r) {
      vm.detailError = errText(r, 'Không thể tải chi tiết cảnh báo AI.');
    }).finally(function () { vm.detailLoading = false; });
  };

  vm.openDetail = function (item) {
    if (!item || !item.id) return;
    vm.selected = item;
    vm.pendingDecision = '';
    vm.reviewerNote = item.reviewer_note || '';
    vm.loadDetail(item.id);
  };

  vm.closeDetail = function () {
    vm.selected = null;
    vm.selectedDetail = null;
    vm.safeFeatures = [];
    vm.detailError = '';
    vm.reviewerNote = '';
    vm.pendingDecision = '';
  };

  vm.chooseDecision = function (status) {
    vm.pendingDecision = status;
  };

  vm.cancelDecision = function () {
    vm.pendingDecision = '';
  };

  vm.submitReview = function () {
    if (!vm.selected || !vm.pendingDecision) return;
    var targetId = vm.selected.id;
    var targetStatus = vm.pendingDecision;
    vm.saving = true;
    vm.detailError = '';
    $http.put('/api/v1/admin/ai/risk-scores/' + encodeURIComponent(targetId) + '/review', {
      status: targetStatus,
      reviewerNote: (vm.reviewerNote || '').slice(0, 1000)
    }, {
      withCredentials: true
    }).then(function (r) {
      var resStatus = (r.data && r.data.status) || targetStatus;
      vm.error = false;
      vm.message = 'Đã cập nhật cảnh báo AI #' + targetId + ' sang trạng thái ' + vm.statusLabel(resStatus) + '.';
      vm.closeDetail();
      notifyBadgesDirty();
      return vm.load(vm.page, true);
    }, function (r) {
      vm.detailError = errText(r, 'Không thể gửi kết quả duyệt cảnh báo AI.');
    }).finally(function () { vm.saving = false; });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, function () { vm.load(vm.page); });
  }
  vm.load(0);
}
