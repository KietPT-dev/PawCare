function PawCareAdminFinanceCtrl($http){
  var vm=this;
  vm.data={summary:{},ledger:[],withdrawals:[],disputes:[],histories:[],bookingStatuses:[]};
  vm.filter={type:'',status:'PENDING',from:'',to:''}; vm.loading=false;
  vm.money=function(v){return Number(v||0).toLocaleString('vi-VN')+' ₫'};
  vm.errorText=function(r){var d=r&&r.data;return (d&&(d.error||d.message))||('HTTP '+((r&&r.status)||'unknown')+': Không thể tải dữ liệu.');};
  vm.fail=function(r){vm.error=true;vm.message=vm.errorText(r);};
  vm.load=function(){var q=[];['type','status','from','to'].forEach(function(k){if(vm.filter[k])q.push(k+'='+encodeURIComponent(vm.filter[k]))});vm.loading=true;return $http.get('/bonita/API/extension/finance'+(q.length?'?'+q.join('&'):'' )).then(function(r){vm.error=false;vm.message='';vm.data=r.data||vm.data;return r.data},function(r){vm.fail(r)}).finally(function(){vm.loading=false})};
  vm.refresh=function(){vm.load()};
  vm.open=function(w){vm.selected=w;vm.note=w.admin_note||''};
  vm.decide=function(decision){if(!vm.selected)return;var msg=decision==='APPROVED'?'Xác nhận đã chuyển khoản đúng số tiền và đúng người nhận?':'Từ chối lệnh rút và hoàn lại số dư ví?';if(!window.confirm(msg))return;$http.put('/bonita/API/extension/finance',{id:vm.selected.id,decision:decision,admin_note:vm.note}).then(function(){vm.message=decision==='APPROVED'?'Đã xác nhận chuyển khoản.':'Đã từ chối và hoàn tiền vào ví.';vm.selected=null;vm.load()},vm.fail)};
  vm.history=function(bookingId){return vm.data.histories.filter(function(x){return String(x.booking_id)===String(bookingId)})};
  vm.load();
}
