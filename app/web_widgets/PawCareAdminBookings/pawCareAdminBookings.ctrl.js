function PawCareAdminBookingsCtrl($scope, $http) {
  var vm = this;
  var U = window.PawCareAdmin || {};

  vm.rows = [];
  vm.filtered = [];
  vm.paged = { items: [], page: 0, size: 15, total: 0, totalPages: 1, from: 0, to: 0 };
  vm.statuses = ['PENDING', 'CONFIRMED', 'CHECKED_IN', 'IN_SERVICE', 'COMPLETED', 'CANCELLED', 'REJECTED'];
  vm.query = '';
  vm.statusFilter = '';
  vm.dateFilter = '';
  vm.page = 0;
  vm.loading = false;
  vm.message = '';
  vm.error = false;
  vm.selected = null;
  vm.stats = { total: 0, active: 0, completed: 0, cancelledOrDisputed: 0, totalAmount: 0 };

  vm.money = function (v) { return U.formatMoney ? U.formatMoney(v) : (Number(v || 0).toLocaleString('vi-VN') + ' ₫'); };
  vm.formatDateTime = function (v) { return U.formatDateTime ? U.formatDateTime(v) : String(v || '—'); };
  vm.formatDateOnly = function (v) { return U.formatDateOnly ? U.formatDateOnly(v) : String(v || '—'); };
  vm.formatTimeOnly = function (v) { return U.formatTimeOnly ? U.formatTimeOnly(v) : ''; };
  vm.statusLabel = function (s) { return U.statusLabel ? U.statusLabel(s) : s; };
  vm.statusClass = function (s) { return U.statusClass ? U.statusClass(s) : 'pc-badge'; };

  function err(r) {
    vm.error = true;
    vm.message = U.errorText ? U.errorText(r, 'Không thể tải booking.') : 'Không thể tải booking.';
  }

  function computeStats() {
    var active = 0, completed = 0, cancelledOrDisputed = 0, totalAmount = 0;
    vm.rows.forEach(function (b) {
      var st = String(b.status || '').toUpperCase();
      totalAmount += Number(b.estimated_price || 0);
      if (st === 'COMPLETED') completed++;
      else if (st === 'CANCELLED' || st === 'REJECTED' || st === 'DISPUTED') cancelledOrDisputed++;
      else active++;
    });
    vm.stats = {
      total: vm.rows.length,
      active: active,
      completed: completed,
      cancelledOrDisputed: cancelledOrDisputed,
      totalAmount: totalAmount
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
    var targetDate = '';
    if (vm.dateFilter) {
      if (typeof vm.dateFilter === 'string') targetDate = vm.dateFilter;
      else if (vm.dateFilter instanceof Date && !isNaN(vm.dateFilter.getTime())) {
        targetDate = U.toDateKey ? U.toDateKey(vm.dateFilter.getTime()) : '';
      }
    }

    vm.filtered = vm.rows.filter(function (b) {
      if (vm.statusFilter && b.status !== vm.statusFilter) return false;
      if (targetDate) {
        var bDate = U.toDateKey ? U.toDateKey(b.booking_start) : '';
        if (bDate !== targetDate) return false;
      }
      if (q) {
        var hay = [b.id, b.provider_name, b.status, b.customer_note, b.provider_note].join(' ').toLowerCase();
        if (hay.indexOf(q) === -1) return false;
      }
      return true;
    });
    vm.updatePage();
  };

  vm.clearFilters = function () {
    vm.query = '';
    vm.statusFilter = '';
    vm.dateFilter = '';
    vm.applyFilter(true);
  };

  vm.load = function () {
    vm.loading = true;
    $http.get('/bonita/API/extension/bookings', { params: { c: 100 } }).then(function (r) {
      vm.error = false;
      vm.rows = (r.data && r.data.data) || [];
      vm.rows.forEach(function (b) { b.nextStatus = b.status; });
      computeStats();
      vm.applyFilter(false);
    }, err).finally(function () { vm.loading = false; });
  };

  vm.save = function (b) {
    if (b.nextStatus === b.status) {
      vm.error = true;
      vm.message = 'Chọn trạng thái mới trước khi lưu.';
      return;
    }
    $http.put('/bonita/API/extension/bookings', {
      id: b.id,
      status: b.nextStatus,
      note: 'Updated by PawCare Admin'
    }).then(function () {
      vm.error = false;
      vm.message = 'Đã cập nhật Booking #' + b.id + ' sang ' + vm.statusLabel(b.nextStatus) + '.';
      vm.load();
    }, err);
  };

  if (U.bindShellRefresh) {
    U.bindShellRefresh($scope, vm.load);
  }
  vm.load();
}
