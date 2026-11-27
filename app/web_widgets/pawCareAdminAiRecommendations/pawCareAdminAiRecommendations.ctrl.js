function PawCareAdminAiRecommendationsCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.filtered = [];
  vm.paged = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.page = 0;
  vm.statusFilter = '';
  vm.typeFilter = '';
  vm.query = '';
  vm.loading = false;
  vm.saving = false;
  vm.message = '';
  vm.error = false;
  vm.hasPayloadGap = false;
  vm.selected = null;
  vm.reviewerNote = '';
  vm.pendingDecision = '';
  vm.stats = { total: 0, open: 0, indexCount: 0, forecastCount: 0 };

  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : (s || '—'); };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };
  vm.go = function (token) { if (U.navigate) U.navigate(token); };

  vm.formatMetric = function (v, decimals) {
    if (v === null || v === undefined || v === '') return '—';
    var n = Number(v);
    return isNaN(n) ? '—' : n.toFixed(decimals || 3);
  };

  vm.formatConfidence = function (v) {
    if (v === null || v === undefined || v === '') return '—';
    var n = Number(v);
    if (isNaN(n)) return '—';
    return (n * 100).toFixed(1) + '%';
  };

  vm.formatColumns = function (cols) {
    if (Array.isArray(cols) && cols.length > 0) return cols.join(', ');
    if (typeof cols === 'string' && cols.trim()) return cols.trim();
    return '';
  };

  function errText(r, fallback) {
    return U.errorText ? U.errorText(r, fallback) : (fallback || 'Không thể tải khuyến nghị AI.');
  }

  function normalizeRow(item) {
    var parsed = U.safeParseJson ? U.safeParseJson(item.payload) : null;
    item._hasPayload = !!(parsed && typeof parsed === 'object');
    item._payload = item._hasPayload ? parsed : {};
    return item;
  }

  function computeStats() {
    var open = 0, indexCount = 0, forecastCount = 0, missingPayload = false;
    vm.rows.forEach(function (r) {
      var st = String(r.status || '').toUpperCase();
      var tp = String(r.recommendation_type || '').toUpperCase();
      if (st === 'OPEN') open++;
      if (tp === 'INDEX') indexCount++;
      else if (tp === 'CAPACITY_FORECAST') forecastCount++;
      if (!r._hasPayload) missingPayload = true;
    });
    vm.hasPayloadGap = vm.rows.length > 0 && missingPayload;
    vm.stats = {
      total: vm.rows.length,
      open: open,
      indexCount: indexCount,
      forecastCount: forecastCount
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
    vm.filtered = vm.rows.filter(function (r) {
      if (vm.typeFilter && String(r.recommendation_type || '').toUpperCase() !== vm.typeFilter) return false;
      if (q) {
        var hay = [
          r.id, r.recommendation_type, r.subject_name, r.model_name,
          r.model_version, r.status, r.reviewer_note,
          r._payload && r._payload.table,
          r._payload && r._payload.reason,
          r._payload && r._payload.assumption
        ].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
    vm.updatePage();
  };

  vm.setTypeFilter = function (tp) {
    vm.typeFilter = tp;
    vm.applyFilter(true);
  };

  vm.clearFilters = function () {
    vm.query = '';
    vm.typeFilter = '';
    if (vm.statusFilter) {
      vm.statusFilter = '';
      vm.load();
    } else {
      vm.applyFilter(true);
    }
  };

  vm.load = function (keepMessage) {
    vm.loading = true;
    var opts = { withCredentials: true };
    if (vm.statusFilter) opts.params = { status: vm.statusFilter };

    return $http.get('/api/v1/admin/ai/operational-recommendations', opts).then(function (r) {
      var list = Array.isArray(r.data) ? r.data : ((r.data && (r.data.items || r.data.data)) || []);
      vm.error = false;
      if (!keepMessage) vm.message = '';
      vm.rows = list.map(normalizeRow);
      computeStats();
      vm.applyFilter(false);
    }, function (r) {
      vm.error = true;
      vm.rows = [];
      vm.filtered = [];
      vm.hasPayloadGap = false;
      computeStats();
      vm.updatePage();
      vm.message = errText(r, 'Không thể tải danh sách khuyến nghị vận hành AI.');
    }).finally(function () { vm.loading = false; });
  };

  vm.openDetail = function (item) {
    vm.selected = item;
    vm.reviewerNote = item.reviewer_note || '';
    vm.pendingDecision = '';
  };

  vm.closeDetail = function () {
    vm.selected = null;
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
    $http.put('/api/v1/admin/ai/operational-recommendations/' + encodeURIComponent(targetId) + '/review', {
      status: targetStatus,
      reviewerNote: (vm.reviewerNote || '').slice(0, 1000)
    }, {
      withCredentials: true
    }).then(function (r) {
      var resStatus = (r.data && r.data.status) || targetStatus;
      vm.error = false;
      vm.message = 'Đã ghi nhận khuyến nghị #' + targetId + ' sang trạng thái ' + vm.statusLabel(resStatus) + '.';
      vm.closeDetail();
      return vm.load(true);
    }, function (r) {
      vm.error = true;
      vm.message = errText(r, 'Không thể cập nhật trạng thái khuyến nghị vận hành.');
    }).finally(function () { vm.saving = false; });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, function () { vm.load(); });
  }
  vm.load();
}
