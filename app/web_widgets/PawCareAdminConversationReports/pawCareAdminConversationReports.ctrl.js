function PawCareAdminConversationReportsCtrl($http) {
  var vm = this;
  vm.status = 'OPEN'; vm.page = 0; vm.size = 20; vm.data = {content: [], totalPages: 0};
  vm.loading = false; vm.messagesLoading = false; vm.selected = null; vm.messages = [];
  vm.errorText = function (response) {
    var data = response && response.data;
    return (data && (data.error || data.message)) || ('HTTP ' + ((response && response.status) || 'unknown') + ': Không thể hoàn tất yêu cầu.');
  };
  vm.fail = function (response) { vm.error = true; vm.message = vm.errorText(response); };
  vm.load = function (page) {
    vm.page = angular.isNumber(page) ? page : vm.page; vm.loading = true;
    return $http.get('/bonita/API/extension/conversation-reports', {params: {status: vm.status, page: vm.page, size: vm.size}})
      .then(function (response) { vm.error = false; vm.message = ''; vm.data = response.data || vm.data; }, vm.fail)
      .finally(function () { vm.loading = false; });
  };
  vm.select = function (report) {
    vm.selected = report; vm.messages = []; vm.messagesError = ''; vm.messagesLoading = true;
    $http.get('/bonita/API/extension/conversation-messages', {params: {conversation_id: report.conversation_id, size: 50}})
      .then(function (response) { vm.messages = (response.data && response.data.messages) || []; }, function (response) { vm.messagesError = vm.errorText(response); })
      .finally(function () { vm.messagesLoading = false; });
  };
  vm.close = function () { vm.selected = null; vm.messages = []; vm.messagesError = ''; };
  vm.update = function (status) {
    if (!vm.selected || !window.confirm('Xác nhận chuyển report #' + vm.selected.report_id + ' sang ' + status + '?')) return;
    vm.saving = true;
    $http.put('/bonita/API/extension/conversation-reports', {report_id: vm.selected.report_id, status: status, reviewerNote: vm.reviewerNote || ''})
      .then(function () { vm.message = 'Đã cập nhật trạng thái report.'; vm.error = false; vm.close(); return vm.load(0); }, vm.fail)
      .finally(function () { vm.saving = false; });
  };
  vm.previous = function () { if (vm.page > 0) vm.load(vm.page - 1); };
  vm.next = function () { if (vm.page + 1 < (vm.data.totalPages || 0)) vm.load(vm.page + 1); };
  vm.load(0);
}
