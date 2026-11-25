function PawCareAdminConversationReportsCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.status = 'OPEN';
  vm.page = 0;
  vm.size = 20;
  vm.query = '';
  vm.data = { content: [], totalPages: 0, totalElements: 0 };
  vm.filteredRows = [];
  vm.loading = false;
  vm.messagesLoading = false;
  vm.saving = false;
  vm.selected = null;
  vm.messages = [];
  vm.messagesError = '';
  vm.reviewerNote = '';
  vm.pendingDecision = '';
  vm.message = '';
  vm.error = false;

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

  function errorText(response) {
    return U.errorText ? U.errorText(response, 'Không thể hoàn tất yêu cầu.') : 'Không thể hoàn tất yêu cầu.';
  }

  vm.fail = function (response) {
    vm.error = true;
    vm.message = errorText(response);
  };

  vm.applyLocalSearch = function () {
    var rows = (vm.data && vm.data.content) || [];
    var q = (vm.query || '').toLowerCase().trim();
    if (!q) {
      vm.filteredRows = rows;
      return;
    }
    vm.filteredRows = rows.filter(function (r) {
      var hay = [
        r.report_id, r.booking_id, r.conversation_id,
        r.reporter_name, r.customer_name, r.provider_name,
        r.category, r.note, r.reviewer_name, r.status
      ].join(' ').toLowerCase();
      return hay.indexOf(q) !== -1;
    });
  };

  vm.load = function (page) {
    vm.page = angular.isNumber(page) ? page : vm.page;
    vm.loading = true;
    return $http.get('/bonita/API/extension/conversation-reports', {
      params: { status: vm.status, page: vm.page, size: vm.size }
    }).then(function (response) {
      vm.error = false;
      vm.data = response.data || { content: [], totalPages: 0, totalElements: 0 };
      vm.applyLocalSearch();
    }, vm.fail).finally(function () { vm.loading = false; });
  };

  vm.switchStatus = function (st) {
    vm.status = st;
    vm.query = '';
    vm.load(0);
  };

  vm.select = function (report) {
    vm.selected = report;
    vm.reviewerNote = report.reviewer_note || '';
    vm.pendingDecision = '';
    vm.messages = [];
    vm.messagesError = '';
    vm.messagesLoading = true;
    $http.get('/bonita/API/extension/conversation-messages', {
      params: { conversation_id: report.conversation_id, size: 50 }
    }).then(function (response) {
      vm.messages = (response.data && response.data.messages) || [];
    }, function (response) {
      vm.messagesError = errorText(response);
    }).finally(function () { vm.messagesLoading = false; });
  };

  vm.close = function () {
    vm.selected = null;
    vm.messages = [];
    vm.messagesError = '';
    vm.reviewerNote = '';
    vm.pendingDecision = '';
  };

  vm.confirmDecision = function (status) {
    vm.pendingDecision = status;
  };

  vm.cancelDecision = function () {
    vm.pendingDecision = '';
  };

  vm.update = function (status) {
    var targetStatus = status || vm.pendingDecision;
    if (!vm.selected || !targetStatus) return;
    vm.saving = true;
    var reportId = vm.selected.report_id;
    $http.put('/bonita/API/extension/conversation-reports', {
      report_id: reportId,
      status: targetStatus,
      reviewerNote: vm.reviewerNote || ''
    }).then(function () {
      vm.error = false;
      vm.message = 'Đã cập nhật Report #' + reportId + ' sang ' + vm.statusLabel(targetStatus) + '.';
      vm.close();
      notifyBadgesDirty();
      return vm.load(0);
    }, vm.fail).finally(function () { vm.saving = false; });
  };

  vm.previous = function () {
    if (vm.page > 0) vm.load(vm.page - 1);
  };

  vm.next = function () {
    if (vm.page + 1 < (vm.data.totalPages || 0)) vm.load(vm.page + 1);
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, function () { vm.load(vm.page); });
  }
  vm.load(0);
}
