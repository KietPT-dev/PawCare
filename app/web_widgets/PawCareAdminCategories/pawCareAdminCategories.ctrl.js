function PawCareAdminCategoriesCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.filtered = [];
  vm.paged = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.draft = { name: '', description: '', is_active: true };
  vm.query = '';
  vm.page = 0;
  vm.activeCount = 0;
  vm.loading = false;
  vm.saving = false;
  vm.formOpen = false;
  vm.deleteTarget = null;
  vm.message = '';
  vm.error = false;

  function err(r) {
    vm.error = true;
    vm.message = U.errorText ? U.errorText(r, 'Không thể tải danh mục.') : 'Không thể tải danh mục.';
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
      if (!q) return true;
      return [c.id, c.name, c.description].join(' ').toLowerCase().indexOf(q) !== -1;
    });
    vm.updatePage();
  };

  vm.load = function () {
    vm.loading = true;
    $http.get('/bonita/API/extension/categories', { params: { c: 100 } }).then(function (r) {
      vm.error = false;
      vm.rows = (r.data && r.data.data) || [];
      vm.activeCount = vm.rows.filter(function (c) {
        return c.is_active === 1 || c.is_active === true || c.is_active === undefined;
      }).length;
      vm.applyFilter(false);
    }, err).finally(function () { vm.loading = false; });
  };

  vm.openCreate = function () {
    vm.draft = { name: '', description: '', is_active: true };
    vm.formOpen = true;
  };

  vm.openEdit = function (c) {
    vm.draft = angular.copy(c);
    vm.draft.is_active = (c.is_active === 1 || c.is_active === true || c.is_active === undefined);
    vm.formOpen = true;
  };

  vm.save = function () {
    vm.saving = true;
    var payload = {
      id: vm.draft.id,
      name: vm.draft.name,
      description: vm.draft.description,
      is_active: vm.draft.is_active ? 1 : 0
    };
    var q = vm.draft.id
      ? $http.put('/bonita/API/extension/categories', payload)
      : $http.post('/bonita/API/extension/categories', payload);
    q.then(function () {
      vm.error = false;
      vm.message = vm.draft.id ? 'Đã cập nhật danh mục.' : 'Đã thêm danh mục mới.';
      vm.formOpen = false;
      vm.draft = { name: '', description: '', is_active: true };
      vm.load();
    }, err).finally(function () { vm.saving = false; });
  };

  vm.askRemove = function (c) {
    vm.deleteTarget = c;
  };

  vm.confirmRemove = function () {
    if (!vm.deleteTarget) return;
    vm.saving = true;
    $http.delete('/bonita/API/extension/categories?id=' + encodeURIComponent(vm.deleteTarget.id)).then(function () {
      vm.error = false;
      vm.message = 'Đã xóa danh mục ' + vm.deleteTarget.name + '.';
      vm.deleteTarget = null;
      vm.load();
    }, err).finally(function () { vm.saving = false; });
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
