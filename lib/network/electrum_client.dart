import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../domain/utxo.dart';

class ElectrumException implements Exception { const ElectrumException(this.message); final String message; @override String toString()=>message; }

class ElectrumClient {
 ElectrumClient({this.host='wallet.mobick.info',this.port=40009,this.useTls=true,this.timeout=const Duration(seconds:15)});
 final String host; final int port; final bool useTls; final Duration timeout;
 Socket? _socket; StreamIterator<String>? _lines; int _requestId=0;

 Future<void> connect() async {
  if(_socket!=null)return;
  final Socket s=useTls
    ? await SecureSocket.connect(host,port,timeout:timeout,onBadCertificate:(_)=>false)
    : await Socket.connect(host,port,timeout:timeout);
  _socket=s; _lines=StreamIterator(s.cast<List<int>>().transform(utf8.decoder).transform(const LineSplitter()));
  final v=await request('server.version',['btcmobick-coin-control','1.4']);
  if(v==null){await close();throw const ElectrumException('ElectrumX handshake failed.');}
 }
 Future<dynamic> request(String method,List<dynamic> params) async {
  final s=_socket,l=_lines; if(s==null||l==null)throw const ElectrumException('ElectrumX is not connected.');
  final id=++_requestId;
  s.write('${jsonEncode({'id':id,'method':method,'params':params})}\n'); await s.flush();
  for(var n=0;n<100;n++){
   final ok=await l.moveNext().timeout(timeout); if(!ok)throw const ElectrumException('ElectrumX connection closed.');
   final d=jsonDecode(l.current); if(d is! Map<String,dynamic>||d['id']!=id)continue;
   if(d['error']!=null)throw ElectrumException('ElectrumX error: ${d['error']}'); return d['result'];
  }
  throw const ElectrumException('Too many unrelated ElectrumX messages.');
 }
 Future<List<Utxo>> listUnspent(String sh) async {
  final r=await request('blockchain.scripthash.listunspent',[sh]); if(r is! List)throw const ElectrumException('Malformed listunspent response.');
  return r.map((x){if(x is! Map)throw const FormatException('Malformed UTXO item.');return Utxo.fromElectrumJson(Map<String,dynamic>.from(x));}).toList(growable:false);
 }
 Future<void> close() async {final l=_lines;_lines=null;if(l!=null)await l.cancel();_socket?.destroy();_socket=null;}
}