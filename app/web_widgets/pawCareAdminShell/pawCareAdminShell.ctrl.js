function PawCareAdminShellCtrl($scope, $http, $window, $timeout, $sce) {
  var vm = this;

  vm.collapsed = false;
  try {
    vm.collapsed = $window.localStorage.getItem('pawcareAdminSidebarCollapsed') === '1';
  } catch (e) {}

  vm.mobileOpen = false;
  vm.notifOpen = false;
  vm.userOpen = false;
  vm.showProfileModal = false;
  vm.syncing = false;

  vm.application = null;
  vm.applicationToken = 'pawcare-admin';
  vm.homePageToken = 'dashboard';
  vm.pageToken = 'dashboard';
  vm.menus = [];
  vm.navGroups = [];
  vm.notifications = [];
  vm.unreadNotifCount = 0;
  vm.badges = {};

  vm.userName = 'Admin PawCare';
  vm.userInitials = 'AD';
  vm.userEmail = '';
  vm.sessionUserName = '';
  vm.logoutHidden = false;
  vm.logoutUrl = '../../../logoutservice?redirect=true';

  var ICONS = {
    dashboard: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="7" height="9" x="3" y="3" rx="1"/><rect width="7" height="5" x="14" y="3" rx="1"/><rect width="7" height="9" x="14" y="12" rx="1"/><rect width="7" height="5" x="3" y="16" rx="1"/></svg>',
    users: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>',
    providers: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><path d="m9 14 2 2 4-4"/></svg>',
    categories: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 2H2v10l9.29 9.29c.94.94 2.48.94 3.42 0l6.58-6.58c.94-.94.94-2.48 0-3.42L12 2Z"/><path d="M7 7h.01"/></svg>',
    bookings: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><rect width="18" height="18" x="3" y="4" rx="2" ry="2"/><line x1="16" x2="16" y1="2" y2="6"/><line x1="8" x2="8" y1="2" y2="6"/><line x1="3" x2="21" y1="10" y2="10"/></svg>',
    complaints: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z"/><line x1="12" x2="12" y1="7" y2="11"/><line x1="12" x2="12.01" y1="14" y2="14"/></svg>',
    finance: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M21 12V7H5a2 2 0 0 1 0-4h14v4"/><path d="M3 5v14a2 2 0 0 0 2 2h16v-5"/><path d="M18 12a2 2 0 0 0 0 4h4v-4Z"/></svg>',
    disputes: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="m16 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="m2 16 3-8 3 8c-.87.65-1.92 1-3 1s-2.13-.35-3-1Z"/><path d="M7 21h10"/><path d="M12 3v18"/><path d="M3 7h2c2 0 5-1 7-2 2 1 5 2 7 2h2"/></svg>',
    'conversation-reports': '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M12 22s8-4 8-10V5l-8-3-8 3v7c0 6 8 10 8 10z"/><line x1="12" x2="12" y1="8" y2="12"/><line x1="12" x2="12.01" y1="16" y2="16"/></svg>',
    defaultIcon: '<svg width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><circle cx="12" cy="12" r="9"/></svg>'
  };

  vm.iconFor = function (token) {
    return $sce.trustAsHtml(ICONS[token] || ICONS.defaultIcon);
  };

  vm.badgeFor = function (token) {
    return Number(vm.badges[token] || 0);
  };

  vm.toggleCollapse = function () {
    vm.collapsed = !vm.collapsed;
    try {
      $window.localStorage.setItem('pawcareAdminSidebarCollapsed', vm.collapsed ? '1' : '0');
    } catch (e) {}
  };

  vm.toggleNotif = function () {
    vm.notifOpen = !vm.notifOpen;
    vm.userOpen = false;
  };

  vm.toggleUser = function () {
    vm.userOpen = !vm.userOpen;
    vm.notifOpen = false;
  };

  vm.formatDate = function (val) {
    if (window.PawCareAdmin && window.PawCareAdmin.formatDateTime) {
      return window.PawCareAdmin.formatDateTime(val);
    }
    if (!val) return '';
    if (typeof val === 'object' && val.year && val.dayOfMonth) {
      var m = val.monthValue || 1;
      var dd = val.dayOfMonth < 10 ? '0' + val.dayOfMonth : val.dayOfMonth;
      var mm = m < 10 ? '0' + m : m;
      var hh = (val.hour || 0) < 10 ? '0' + (val.hour || 0) : (val.hour || 0);
      var mi = (val.minute || 0) < 10 ? '0' + (val.minute || 0) : (val.minute || 0);
      return dd + '/' + mm + '/' + val.year + ' ' + hh + ':' + mi;
    }
    return String(val);
  };

  function parseUrlTokens() {
    var parts = ($window.location.pathname || '').split('/').filter(Boolean);
    if (parts.length >= 2) {
      vm.applicationToken = parts[parts.length - 2] || vm.applicationToken;
      vm.pageToken = parts[parts.length - 1] || vm.pageToken;
      // Handle trailing slash: /bonita/apps/<appToken>/<pageToken>/
      var raw = ($window.location.pathname || '').split('/');
      if (raw.length >= 3) {
        vm.applicationToken = raw[raw.length - 3] || vm.applicationToken;
        vm.pageToken = raw[raw.length - 2] || vm.pageToken;
      }
    }
  }

  function buildNavGroups(menus) {
    var normalized = (menus || []).map(function (m) {
      return {
        token: m.applicationPageId && m.applicationPageId.token ? m.applicationPageId.token : '',
        displayName: m.displayName || 'Trang'
      };
    }).filter(function (m) { return !!m.token; });

    // Fallback default 9 pages when running standalone preview
    if (!normalized.length) {
      normalized = [
        { token: 'dashboard', displayName: 'Tổng quan' },
        { token: 'users', displayName: 'Người dùng' },
        { token: 'providers', displayName: 'Duyệt Provider' },
        { token: 'categories', displayName: 'Danh mục' },
        { token: 'bookings', displayName: 'Booking' },
        { token: 'complaints', displayName: 'Khiếu nại' },
        { token: 'finance', displayName: 'Tài chính sàn' },
        { token: 'disputes', displayName: 'Tranh chấp' },
        { token: 'conversation-reports', displayName: 'Báo cáo hội thoại' }
      ];
    }

    var overviewTokens = ['dashboard'];
    var opsTokens = ['users', 'providers', 'categories', 'bookings'];
    var financeTokens = ['finance', 'complaints', 'disputes', 'conversation-reports'];

    var overview = [];
    var ops = [];
    var finance = [];
    var others = [];

    normalized.forEach(function (item) {
      if (overviewTokens.indexOf(item.token) !== -1) overview.push(item);
      else if (opsTokens.indexOf(item.token) !== -1) ops.push(item);
      else if (financeTokens.indexOf(item.token) !== -1) finance.push(item);
      else others.push(item);
    });

    var groups = [];
    if (overview.length) groups.push({ label: '', items: overview });
    if (ops.length) groups.push({ label: 'Vận hành & Đối tác', items: ops });
    if (finance.length) groups.push({ label: 'Tài chính & Kiểm soát', items: finance });
    if (others.length) groups.push({ label: 'Mở rộng', items: others });
    vm.navGroups = groups;
  }

  vm.currentPageLabel = function () {
    for (var i = 0; i < vm.navGroups.length; i++) {
      var items = vm.navGroups[i].items || [];
      for (var j = 0; j < items.length; j++) {
        if (items[j].token === vm.pageToken) return items[j].displayName;
      }
    }
    return 'Tổng quan';
  };

  function mountIframe() {
    $timeout(function () {
      var host = document.getElementById('pawcare-frame-host');
      if (!host) return;
      while (host.firstChild) host.removeChild(host.firstChild);
      var search = $window.location.search || '';
      var sep = search ? '&' : '?';
      var src = '../../../portal/resource/app/' + vm.applicationToken + '/' + vm.pageToken + '/content/' + search + sep + 'app=' + vm.applicationToken;
      var iframe = document.createElement('iframe');
      iframe.id = 'bonitaframe';
      iframe.title = vm.currentPageLabel();
      iframe.src = $sce.trustAsResourceUrl(src);
      host.appendChild(iframe);
    }, 0);
  }

  vm.displayPage = function (token) {
    if (!token) return;
    vm.mobileOpen = false;
    vm.notifOpen = false;
    vm.userOpen = false;

    var prevToken = vm.pageToken;
    var prevPath = $window.location.pathname || '';
    vm.pageToken = token;

    if (prevPath.indexOf('/' + prevToken + '/') !== -1) {
      var nextPath = prevPath.substring(0, prevPath.length - prevToken.length - 1) + token + '/' + ($window.location.search || '');
      if ($window.history && $window.history.pushState) {
        $window.history.pushState({ pageToken: token }, token, nextPath);
      }
    }

    $http.get('../API/system/session/unusedId').then(function () {
      mountIframe();
    }, function () {
      $window.location.reload();
    });
  };

  vm.onMenuClick = function ($event, token) {
    if ($event && $event.preventDefault) $event.preventDefault();
    vm.displayPage(token);
    return false;
  };

  vm.refreshActive = function () {
    vm.syncing = true;
    try {
      var frame = document.getElementById('bonitaframe');
      if (frame && frame.contentWindow) {
        frame.contentWindow.postMessage(JSON.stringify({ message: 'pawcareRefresh' }), '*');
      }
    } catch (e) {}
    loadMetaBadges();
    $timeout(function () {
      vm.syncing = false;
    }, 600);
  };

  vm.openNotification = function (n) {
    vm.notifOpen = false;
    var refType = String((n && (n.reference_type || n.notification_type)) || '').toUpperCase();
    if (refType.indexOf('BOOKING') !== -1) vm.displayPage('bookings');
    else if (refType.indexOf('COMPLAINT') !== -1) vm.displayPage('complaints');
    else if (refType.indexOf('CONVERSATION') !== -1) vm.displayPage('conversation-reports');
    else if (refType.indexOf('PAYMENT') !== -1 || refType.indexOf('WITHDRAWAL') !== -1) vm.displayPage('finance');
    else vm.displayPage('dashboard');
  };

  function loadMetaBadges() {
    $http.get('/bonita/API/extension/notifications?all=true').then(function (r) {
      var rows = (r.data && r.data.data) || [];
      vm.notifications = rows;
      vm.unreadNotifCount = rows.filter(function (x) { return !x.is_read || x.is_read === 0; }).length;
    }, function () {});

    $http.get('/bonita/API/extension/providers').then(function (r) {
      var rows = (r.data && r.data.data) || [];
      vm.badges.providers = rows.filter(function (p) { return p.status === 'PENDING' || p.status === 'NEED_MORE_INFO'; }).length;
    }, function () {});

    $http.get('/bonita/API/extension/finance?status=PENDING').then(function (r) {
      var d = r.data || {};
      vm.badges.finance = (d.summary && Number(d.summary.pending_count || 0)) || ((d.withdrawals || []).filter(function (w) { return w.status === 'PENDING'; }).length);
      vm.badges.disputes = (d.disputes || []).length;
    }, function () {});

    $http.get('/bonita/API/extension/complaints').then(function (r) {
      var rows = (r.data && r.data.data) || [];
      vm.badges.complaints = rows.filter(function (c) { return c.status === 'OPEN' || c.status === 'IN_PROGRESS'; }).length;
    }, function () {});

    $http.get('/bonita/API/extension/conversation-reports', { params: { status: 'OPEN', page: 0, size: 1 } }).then(function (r) {
      vm.badges['conversation-reports'] = (r.data && Number(r.data.totalElements || 0)) || 0;
    }, function () {});
  }

  function init() {
    parseUrlTokens();
    buildNavGroups([]);

    $http.get('../API/system/session/unusedId').then(function (resp) {
      var s = resp.data || {};
      vm.sessionUserName = s.user_name || 'admin';
      try {
        vm.logoutHidden = JSON.parse(s.conf || '[]').indexOf('logout.link.hidden') !== -1;
      } catch (e) {}
      if (s.user_id && s.is_technical_user !== 'true') {
        $http.get('../API/identity/user/' + s.user_id + '?d=professional_data').then(function (uResp) {
          var u = uResp.data || {};
          var full = [u.firstname, u.lastname].filter(Boolean).join(' ').trim();
          vm.userName = full || vm.sessionUserName;
          vm.userEmail = u.professional_data ? u.professional_data.email : '';
          var initials = vm.userName.split(' ').map(function (w) { return w[0]; }).join('').slice(0, 2).toUpperCase();
          vm.userInitials = initials || 'AD';
        });
      } else {
        vm.userName = s.is_technical_user === 'true' ? 'Super Administrator' : vm.sessionUserName;
        vm.userInitials = 'SA';
      }
    });

    $http.get('../API/living/application?c=1&f=token%3D' + encodeURIComponent(vm.applicationToken)).then(function (resp) {
      var apps = resp.data || [];
      if (apps[0]) {
        vm.application = apps[0];
        if (apps[0].displayName) $window.document.title = apps[0].displayName;
        $http.get('../API/living/application-menu/?c=100&f=applicationId%3D' + apps[0].id + '&d=applicationPageId&o=menuIndex+ASC').then(function (mResp) {
          buildNavGroups(mResp.data || []);
        });
      }
    });

    mountIframe();
    loadMetaBadges();
  }

  function onMessage(event) {
    if (!event || !event.data) return;
    try {
      var payload = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
      if (payload && payload.message === 'pawcareNavigate' && payload.pageToken) {
        $scope.$applyAsync(function () {
          vm.displayPage(payload.pageToken);
        });
      } else if (payload && payload.message === 'pawcareBadgesDirty') {
        loadMetaBadges();
      }
    } catch (e) {}
  }

  function onWindowClick() {
    $scope.$applyAsync(function () {
      vm.notifOpen = false;
      vm.userOpen = false;
    });
  }

  function onPopState() {
    parseUrlTokens();
    $scope.$applyAsync(function () {
      mountIframe();
    });
  }

  $window.addEventListener('message', onMessage, false);
  $window.addEventListener('click', onWindowClick, false);
  $window.addEventListener('popstate', onPopState, false);

  $scope.$on('$destroy', function () {
    $window.removeEventListener('message', onMessage, false);
    $window.removeEventListener('click', onWindowClick, false);
    $window.removeEventListener('popstate', onPopState, false);
  });

  init();
}
