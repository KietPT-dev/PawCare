function PawCareAdminFinanceCtrl($http){
  var vm=this; vm.data={summary:{},ledger:[],withdrawals:[],disputes:[]}; vm.filter={type:'',status:'PENDING'};
  vm.money=function(v){return Number(v||0).toLocaleString('vi-VN')+' ₫'};
  vm.err=function(r){vm.error=true;vm.message=(r.data&&r.data.error)||'Không thể thực hiện thao tác tài chính.'};
  vm.load=function(){var q=[];if(vm.filter.type)q.push('type='+encodeURIComponent(vm.filter.type));if(vm.filter.status)q.push('status='+encodeURIComponent(vm.filter.status));$http.get('/bonita/API/extension/finance'+(q.length?'?'+q.join('&'):'' )).then(function(r){vm.error=false;vm.data=r.data||vm.data},vm.err)};
  vm.setType=function(){vm.load()};
  vm.qr=function(w){var bins={VCB:'VCB',VIETCOMBANK:'VCB',MB:'MB',MBBANK:'MB',ACB:'ACB',TCB:'TCB',TECHCOMBANK:'TCB',BIDV:'BIDV',VIB:'VIB',TPB:'TPB',SACOMBANK:'STB',STB:'STB',VPBANK:'VPB',VPB:'VPB'};var key=String(w.bank_name||'').toUpperCase().replace(/[^A-Z0-9]/g,'');var bin=bins[key]||bins[String(w.bank_name||'').toUpperCase()];if(!bin)return null;return 'https://img.vietqr.io/image/'+bin+'-'+encodeURIComponent(w.bank_account_no)+'-compact2.png?amount='+encodeURIComponent(w.amount)+'&addInfo='+encodeURIComponent('PAWCARE WD '+w.id)+'&accountName='+encodeURIComponent(w.bank_account_name)};
  vm.open=function(w){vm.selected=w;vm.selectedQr=vm.qr(w);vm.note=w.admin_note||''};
  vm.decide=function(decision){if(!vm.selected)return;if(decision==='REJECTED'&&!window.confirm('Từ chối lệnh rút và hoàn lại số dư ví?'))return;if(decision==='APPROVED'&&!window.confirm('Xác nhận bạn đã chuyển khoản đúng số tiền và đúng người nhận?'))return;$http.put('/bonita/API/extension/finance',{id:vm.selected.id,decision:decision,admin_note:vm.note}).then(function(){vm.message=decision==='APPROVED'?'Đã xác nhận chuyển khoản.':'Đã từ chối và hoàn tiền vào ví.';vm.selected=null;vm.load()},vm.err)};
  vm.refund=function(d){if(!window.confirm('Force Refund sẽ trả tiền escrow về ví khách hàng. Tiếp tục?'))return;var note=window.prompt('Ghi chú xử lý tranh chấp:',d.admin_response||'');if(note===null)return;$http.post('/bonita/API/extension/finance',{complaint_id:d.id,admin_note:note}).then(function(){vm.message='Đã hoàn tiền escrow về ví khách hàng.';vm.load()},vm.err)};
  vm.load();
}
