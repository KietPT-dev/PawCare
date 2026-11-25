function PawCareAdminUsersCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.filtered = [];
  vm.paged = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.query = '';
  vm.roleFilter = '';
  vm.activeFilter = '';
  vm.page = 0;
  vm.loading = false;
  vm.message = '';
  vm.error = false;
  vm.selected = null;
  vm.stats = { total: 0, customers: 0, providers: 0, admins: 0, active: 0 };

  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };

  function err(r) {
    vm.error = true;
    vm.message = U.errorText ? U.errorText(r, 'Không thể tải người dùng.') : 'Không thể tải người dùng.';
  }

  function computeStats() {
    var customers = 0, providers = 0, admins = 0, active = 0;
    vm.rows.forEach(function (u) {
      if (u.role_code === 'CUSTOMER') customers++;
      else if (u.role_code === 'PROVIDER') providers++;
      else if (u.role_code === 'ADMIN') admins++;
      if (Number(u.is_active) === 1 || u.is_active === true) active++;
    });
    vm.stats = { total: vm.rows.length, customers: customers, providers: providers, admins: admins, active: active };
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
    vm.filtered = vm.rows.filter(function (u) {
      if (vm.roleFilter && u.role_code !== vm.roleFilter) return false;
      if (vm.activeFilter !== '') {
        var activeVal = (Number(u.is_active) === 1 || u.is_active === true) ? '1' : '0';
        if (activeVal !== vm.activeFilter) return false;
      }
      if (q) {
        var hay = [u.id, u.full_name, u.email, u.phone, u.role_code, u.bonita_user_id].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
    vm.updatePage();
  };

  vm.load = function () {
    vm.loading = true;
    $http.get('/bonita/API/extension/users', { params: { c: 100 } }).then(function (r) {
      vm.error = false;
      vm.rows = (r.data && r.data.data) || [];
      vm.rows.forEach(function (u) { u.is_active = (u.is_active === 1 || u.is_active === true) ? 1 : 0; });
      computeStats();
      vm.applyFilter(false);
    }, err).finally(function () { vm.loading = false; });
  };

  vm.save = function (u) {
    $http.put('/bonita/API/extension/users', {
      id: u.id,
      full_name: u.full_name,
      phone: u.phone,
      email: u.email,
      address: u.address,
      role_code: u.role_code,
      is_active: u.is_active
    }).then(function () {
      vm.error = false;
      vm.message = 'Đã cập nhật người dùng #' + u.id + ' (' + u.full_name + ').';
      computeStats();
    }, err);
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
