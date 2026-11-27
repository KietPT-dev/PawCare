(function (window) {
  'use strict';

  var MONTH_MAP = {
    JANUARY: 1, FEBRUARY: 2, MARCH: 3, APRIL: 4, MAY: 5, JUNE: 6,
    JULY: 7, AUGUST: 8, SEPTEMBER: 9, OCTOBER: 10, NOVEMBER: 11, DECEMBER: 12
  };

  function pad2(n) {
    var num = Number(n);
    if (isNaN(num)) return '00';
    return num < 10 ? '0' + num : String(num);
  }

  /**
   * Parses any date/datetime representation from Bonita / Groovy JsonBuilder / MySQL / ISO
   * without introducing timezone offset bugs on LocalDateTime values.
   * Handles:
   *  - Java LocalDateTime JSON objects: { year, monthValue, month, dayOfMonth, hour, minute, second }
   *  - Pre-formatted "dd/MM/yyyy HH:mm" or "dd/MM/yyyy"
   *  - ISO / MySQL strings "2026-11-25T09:30:00" or "2026-11-25 09:30:00"
   *  - Legacy Date maps { time: 17325... } or numeric epoch ms
   */
  function extractParts(val) {
    if (val === null || val === undefined || val === '') return null;

    if (typeof val === 'object') {
      // Java LocalDateTime serialized by Groovy JsonBuilder
      if (val.year !== undefined && (val.monthValue !== undefined || val.month !== undefined) && val.dayOfMonth !== undefined) {
        var month = val.monthValue;
        if (month === undefined && typeof val.month === 'string') {
          month = MONTH_MAP[val.month.toUpperCase()];
        } else if (month === undefined && typeof val.month === 'number') {
          month = val.month;
        }
        return {
          year: Number(val.year),
          month: Number(month || 1),
          day: Number(val.dayOfMonth),
          hour: val.hour !== undefined ? Number(val.hour) : null,
          minute: val.minute !== undefined ? Number(val.minute) : null
        };
      }
      // java.sql.Timestamp / java.util.Date serialized with time millis
      if (typeof val.time === 'number') {
        var dtFromObj = new Date(val.time);
        if (!isNaN(dtFromObj.getTime())) {
          return {
            year: dtFromObj.getFullYear(),
            month: dtFromObj.getMonth() + 1,
            day: dtFromObj.getDate(),
            hour: dtFromObj.getHours(),
            minute: dtFromObj.getMinutes()
          };
        }
      }
      return null;
    }

    if (typeof val === 'number') {
      var dNum = new Date(val);
      if (isNaN(dNum.getTime())) return null;
      return {
        year: dNum.getFullYear(),
        month: dNum.getMonth() + 1,
        day: dNum.getDate(),
        hour: dNum.getHours(),
        minute: dNum.getMinutes()
      };
    }

    var str = String(val).trim();
    if (!str) return null;

    // Already dd/MM/yyyy[ HH:mm]
    var vnMatch = str.match(/^(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2})(?::(\d{2}))?)?$/);
    if (vnMatch) {
      return {
        year: Number(vnMatch[3]),
        month: Number(vnMatch[2]),
        day: Number(vnMatch[1]),
        hour: vnMatch[4] !== undefined ? Number(vnMatch[4]) : null,
        minute: vnMatch[5] !== undefined ? Number(vnMatch[5]) : null
      };
    }

    // ISO or MySQL yyyy-MM-dd[T ]HH:mm[:ss] (preserve exact wall-clock fields if no offset)
    var isoNoTz = str.match(/^(\d{4})-(\d{2})-(\d{2})(?:[T ](\d{2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?)?$/);
    if (isoNoTz) {
      return {
        year: Number(isoNoTz[1]),
        month: Number(isoNoTz[2]),
        day: Number(isoNoTz[3]),
        hour: isoNoTz[4] !== undefined ? Number(isoNoTz[4]) : null,
        minute: isoNoTz[5] !== undefined ? Number(isoNoTz[5]) : null
      };
    }

    // Fallback native Date parse (for Z / explicit timezone offsets)
    var parsed = new Date(str);
    if (!isNaN(parsed.getTime())) {
      return {
        year: parsed.getFullYear(),
        month: parsed.getMonth() + 1,
        day: parsed.getDate(),
        hour: parsed.getHours(),
        minute: parsed.getMinutes()
      };
    }

    return null;
  }

  function formatDateTime(val) {
    if (val === null || val === undefined || val === '') return '—';
    var p = extractParts(val);
    if (!p) {
      return typeof val === 'object' ? '—' : String(val);
    }
    var datePart = pad2(p.day) + '/' + pad2(p.month) + '/' + p.year;
    if (p.hour !== null && p.minute !== null) {
      return datePart + ' ' + pad2(p.hour) + ':' + pad2(p.minute);
    }
    return datePart;
  }

  function formatDateOnly(val) {
    if (val === null || val === undefined || val === '') return '—';
    var p = extractParts(val);
    if (!p) return typeof val === 'object' ? '—' : String(val);
    return pad2(p.day) + '/' + pad2(p.month) + '/' + p.year;
  }

  function formatTimeOnly(val) {
    var p = extractParts(val);
    if (!p || p.hour === null || p.minute === null) return '';
    return pad2(p.hour) + ':' + pad2(p.minute);
  }

  function toDateKey(val) {
    var p = extractParts(val);
    if (!p) return '';
    return p.year + '-' + pad2(p.month) + '-' + pad2(p.day);
  }

  function toTimestamp(val) {
    var p = extractParts(val);
    if (!p) return 0;
    return new Date(p.year, p.month - 1, p.day, p.hour || 0, p.minute || 0).getTime();
  }

  function formatMoney(v) {
    var num = Number(v || 0);
    if (isNaN(num)) num = 0;
    return Math.round(num).toLocaleString('vi-VN') + ' ₫';
  }

  function formatCompactMoney(v) {
    var n = Number(v || 0);
    if (isNaN(n)) return '0';
    var abs = Math.abs(n);
    var sign = n < 0 ? '-' : '';
    if (abs >= 1000000000) return sign + (abs / 1000000000).toFixed(1).replace('.', ',') + ' tỷ';
    if (abs >= 1000000) return sign + (abs / 1000000).toFixed(1).replace('.', ',') + ' tr';
    if (abs >= 1000) return sign + Math.round(abs / 1000) + 'k';
    return sign + String(Math.round(abs));
  }

  var STATUS_TABLE = {
    // Booking & General
    PENDING: { label: 'Chờ xử lý', tone: 'warning' },
    PENDING_PAYMENT: { label: 'Chờ thanh toán', tone: 'neutral' },
    PENDING_APPROVAL: { label: 'Chờ Provider duyệt', tone: 'warning' },
    CONFIRMED: { label: 'Đã xác nhận', tone: 'info' },
    CHECKED_IN: { label: 'Đã check-in', tone: 'info' },
    IN_SERVICE: { label: 'Đang thực hiện', tone: 'info' },
    SERVICE_DONE: { label: 'Chờ khách xác nhận', tone: 'warning' },
    SYSTEM_REVIEW: { label: 'Chờ Admin rà soát', tone: 'warning' },
    COMPLETED: { label: 'Hoàn thành', tone: 'success' },
    CANCELLED: { label: 'Đã hủy', tone: 'danger' },
    REJECTED: { label: 'Đã từ chối', tone: 'danger' },
    DISPUTED: { label: 'Đang tranh chấp', tone: 'danger' },

    // Provider approval
    NEED_MORE_INFO: { label: 'Cần bổ sung', tone: 'warning' },
    APPROVED: { label: 'Đã duyệt', tone: 'success' },
    SUSPENDED: { label: 'Tạm ngưng', tone: 'danger' },

    // Complaints & Reports
    OPEN: { label: 'Đang mở', tone: 'warning' },
    IN_PROGRESS: { label: 'Đang xử lý', tone: 'info' },
    RESOLVED: { label: 'Đã giải quyết', tone: 'success' },
    REVIEWED: { label: 'Đã kiểm duyệt', tone: 'success' },
    DISMISSED: { label: 'Đã bỏ qua', tone: 'neutral' },

    // Finance / Escrow / Ledger
    ESCROW_HELD: { label: 'Đang giữ Escrow', tone: 'info' },
    EXPIRED: { label: 'Đã tất toán / Hết hạn', tone: 'neutral' },
    DEPOSIT: { label: 'Nạp tiền ví', tone: 'info' },
    ESCROW_HOLD: { label: 'Khóa Escrow', tone: 'warning' },
    ESCROW_RELEASE: { label: 'Giải phóng Escrow', tone: 'success' },
    COMMISSION_FEE: { label: 'Phí nền tảng', tone: 'success' },
    PROVIDER_PAYOUT: { label: 'Payout Provider', tone: 'success' },
    WITHDRAWAL: { label: 'Rút tiền', tone: 'neutral' },

    // AI Risk & Operational Recommendations
    LOW: { label: 'Thấp (LOW)', tone: 'success' },
    MEDIUM: { label: 'Trung bình (MEDIUM)', tone: 'warning' },
    HIGH: { label: 'Cao (HIGH)', tone: 'danger' },
    PAYMENT_DEPOSIT: { label: 'Nạp tiền ví', tone: 'info' },
    WALLET_TRANSACTION: { label: 'Giao dịch ví', tone: 'info' },
    WITHDRAWAL_REQUEST: { label: 'Yêu cầu rút tiền', tone: 'warning' },
    BOOKING: { label: 'Đặt lịch', tone: 'neutral' },
    INDEX: { label: 'Đề xuất Index', tone: 'info' },
    CAPACITY_FORECAST: { label: 'Dự báo dung lượng', tone: 'warning' },

    // Roles
    ADMIN: { label: 'ADMIN', tone: 'danger' },
    PROVIDER: { label: 'PROVIDER', tone: 'info' },
    CUSTOMER: { label: 'CUSTOMER', tone: 'neutral' }
  };

  function statusLabel(status) {
    if (!status) return '—';
    var key = String(status).toUpperCase();
    return STATUS_TABLE[key] ? STATUS_TABLE[key].label : String(status);
  }

  function statusTone(status) {
    if (!status) return 'neutral';
    var key = String(status).toUpperCase();
    return STATUS_TABLE[key] ? STATUS_TABLE[key].tone : 'neutral';
  }

  function statusClass(status) {
    return 'pc-badge pc-badge--' + statusTone(status);
  }

  function navigate(pageToken) {
    if (!pageToken) return;
    try {
      if (window.parent && window.parent !== window) {
        window.parent.postMessage(JSON.stringify({
          message: 'pawcareNavigate',
          pageToken: pageToken
        }), '*');
        return;
      }
    } catch (e) {}
    window.location.assign('../' + encodeURIComponent(pageToken) + '/');
  }

  function bindShellRefresh($scope, callback) {
    function handler(event) {
      if (!event || !event.data) return;
      try {
        var payload = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
        if (payload && payload.message === 'pawcareRefresh' && typeof callback === 'function') {
          $scope.$applyAsync(function () {
            callback();
          });
        }
      } catch (e) {}
    }
    window.addEventListener('message', handler, false);
    $scope.$on('$destroy', function () {
      window.removeEventListener('message', handler, false);
    });
  }

  function errorText(response, fallback) {
    var d = response && response.data;
    if (d && (d.error || d.message)) {
      var prefix = response && response.status && response.status > 0 ? ('HTTP ' + response.status + ': ') : '';
      return prefix + (d.error || d.message);
    }
    if (response && response.status === 401) {
      return 'HTTP 401: Chưa xác thực hoặc phiên Admin không có quyền truy cập API AI.';
    }
    if (response && response.status === 403) {
      return 'HTTP 403: Tài khoản không có quyền Quản trị viên (ADMIN).';
    }
    if (response && response.status === 404) {
      return 'HTTP 404: Không tìm thấy bản ghi hoặc đường dẫn API chưa được cấu hình trên máy chủ.';
    }
    if (response && response.status && response.status > 0) {
      return 'HTTP ' + response.status + ': ' + (fallback || 'Không thể hoàn tất yêu cầu.');
    }
    return fallback || 'Không thể kết nối tới máy chủ. Vui lòng thử lại.';
  }

  function safeParseJson(val) {
    if (!val) return null;
    if (typeof val === 'object') return val;
    if (typeof val === 'string') {
      try {
        var parsed = JSON.parse(val);
        return typeof parsed === 'object' ? parsed : null;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  var SAFE_RISK_FEATURES = {
    amount: 'Giá trị giao dịch',
    hourOfDay: 'Giờ trong ngày',
    dayOfWeek: 'Ngày trong tuần',
    accountAgeDays: 'Tuổi tài khoản (ngày)',
    transactionCount10m: 'Số GD trong 10 phút',
    transactionCount1h: 'Số GD trong 1 giờ',
    transactionCount24h: 'Số GD trong 24 giờ',
    amountSum24h: 'Tổng tiền GD 24 giờ',
    priorFailedAttempts: 'Số lần thất bại trước đó',
    eventAgeSeconds: 'Độ trễ sự kiện (giây)'
  };

  function safeRiskFeatures(rawSnapshot) {
    var obj = safeParseJson(rawSnapshot);
    if (!obj || Array.isArray(obj)) return [];
    var entries = [];
    Object.keys(SAFE_RISK_FEATURES).forEach(function (key) {
      if (obj[key] !== undefined && obj[key] !== null && typeof obj[key] !== 'object') {
        entries.push({
          key: key,
          label: SAFE_RISK_FEATURES[key],
          value: obj[key]
        });
      }
    });
    return entries;
  }

  function safeAiRef(type, id) {
    var code = String(type || '').toUpperCase();
    var prefix = 'REF';
    if (code === 'PAYMENT_DEPOSIT') prefix = 'DEP';
    else if (code === 'WALLET_TRANSACTION') prefix = 'WTX';
    else if (code === 'WITHDRAWAL_REQUEST') prefix = 'WDR';
    else if (code === 'BOOKING') prefix = 'BKG';
    return id !== undefined && id !== null && id !== '' ? (prefix + '-#' + id) : '—';
  }

  function paginate(list, pageIndex, pageSize) {
    var arr = Array.isArray(list) ? list : [];
    var size = pageSize || 15;
    var total = arr.length;
    var totalPages = Math.max(1, Math.ceil(total / size));
    var safePage = Math.max(0, Math.min(pageIndex || 0, totalPages - 1));
    var start = safePage * size;
    return {
      items: arr.slice(start, start + size),
      page: safePage,
      size: size,
      total: total,
      totalPages: totalPages,
      from: total === 0 ? 0 : start + 1,
      to: Math.min(total, start + size)
    };
  }

  function presetDateRange(preset) {
    var now = new Date();
    var y = now.getFullYear();
    var m = now.getMonth();
    var d = now.getDate();

    function iso(dt) {
      return dt.getFullYear() + '-' + pad2(dt.getMonth() + 1) + '-' + pad2(dt.getDate());
    }

    if (preset === 'today') {
      var t = iso(now);
      return { from: t, to: t };
    }
    if (preset === '7d') {
      return { from: iso(new Date(y, m, d - 6)), to: iso(now) };
    }
    if (preset === '30d') {
      return { from: iso(new Date(y, m, d - 29)), to: iso(now) };
    }
    if (preset === 'thisMonth') {
      return { from: iso(new Date(y, m, 1)), to: iso(now) };
    }
    if (preset === 'lastMonth') {
      return { from: iso(new Date(y, m - 1, 1)), to: iso(new Date(y, m, 0)) };
    }
    return { from: '', to: '' };
  }

  window.PawCareAdmin = {
    extractParts: extractParts,
    formatDateTime: formatDateTime,
    formatDateOnly: formatDateOnly,
    formatTimeOnly: formatTimeOnly,
    toDateKey: toDateKey,
    toTimestamp: toTimestamp,
    formatMoney: formatMoney,
    formatCompactMoney: formatCompactMoney,
    statusLabel: statusLabel,
    statusTone: statusTone,
    statusClass: statusClass,
    navigate: navigate,
    bindShellRefresh: bindShellRefresh,
    errorText: errorText,
    safeParseJson: safeParseJson,
    safeRiskFeatures: safeRiskFeatures,
    safeAiRef: safeAiRef,
    paginate: paginate,
    presetDateRange: presetDateRange
  };
})(window);
