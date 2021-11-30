/*
Title: T2Ti ERP 3.0
Description: Service utilizado para cadastrar o CFOP na regatuarda da SH
                                                                                
The MIT License                                                                 
                                                                                
Copyright: Copyright (C) 2021 T2Ti.COM                                          
                                                                                
Permission is hereby granted, free of charge, to any person                     
obtaining a copy of this software and associated documentation                  
files (the "Software"), to deal in the Software without                         
restriction, including without limitation the rights to use,                    
copy, modify, merge, publish, distribute, sublicense, and/or sell               
copies of the Software, and to permit persons to whom the                       
Software is furnished to do so, subject to the following                        
conditions:                                                                     
                                                                                
The above copyright notice and this permission notice shall be                  
included in all copies or substantial portions of the Software.                 
                                                                                
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,                 
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES                 
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND                        
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT                     
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,                    
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING                    
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR                   
OTHER DEALINGS IN THE SOFTWARE.                                                 
                                                                                
       The author may be contacted at:                                          
           t2ti.com@gmail.com                                                   
                                                                                
@author Albert Eije (alberteije@gmail.com)                    
@version 1.0.0
*******************************************************************************/
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' show Client;

import 'package:pegasus_pdv/src/service/service_base.dart';
import 'package:pegasus_pdv/src/model/filtro.dart';
import 'package:pegasus_pdv/src/model/model.dart';

/// classe responsável por requisições ao servidor REST
class CfopService extends ServiceBase {
  var clienteHTTP = Client();

  Future<List<CfopModel>?> consultarLista({Filtro? filtro}) async {
    List<CfopModel> listaCfopModel = [];

    tratarFiltro(filtro, '/cfop/');
    final response = await clienteHTTP.get(Uri.tryParse(url)!);

    if (response.statusCode == 200) {
      if (response.headers["content-type"]!.contains("html")) {
        tratarRetornoErro(response.body, response.headers);
        return null;
      } else {
        var parsed = json.decode(response.body) as List<dynamic>;
        for (var cfop in parsed) {
          listaCfopModel.add(CfopModel.fromJson(cfop));
        }
        return listaCfopModel;
      }
    } else {
      tratarRetornoErro(response.body, response.headers);
      return null;
    }
  }

  Future<CfopModel?> consultarObjeto(int id) async {
    final response = await clienteHTTP.get(Uri.http(endpoint, 'cfop/$id'));

    if (response.statusCode == 200) {
      if (response.headers["content-type"]!.contains("html")) {
        tratarRetornoErro(response.body, response.headers);
        return null;
      } else {
        var cfopJson = json.decode(response.body);
        return CfopModel.fromJson(cfopJson);
      }
    } else {
      tratarRetornoErro(response.body, response.headers);
      return null;
    }
  }

  Future<CfopModel?> inserir(CfopModel cfop) async {
    final response = await clienteHTTP.post(
      Uri.tryParse('$endpoint/cfop')!,
      headers: {"content-type": "application/json"},
      body: cfop.objetoEncodeJson(cfop),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.headers["content-type"]!.contains("html")) {
        tratarRetornoErro(response.body, response.headers);
        return null;
      } else {
        var cfopJson = json.decode(response.body);
        return CfopModel.fromJson(cfopJson);
      }
    } else {
      tratarRetornoErro(response.body, response.headers);
      return null;
    }
  }

  Future<CfopModel?> alterar(CfopModel cfop) async {
    var id = cfop.id;
    final response = await clienteHTTP.put(
      Uri.tryParse('$endpoint/cfop/$id')!,
      headers: {"content-type": "application/json"},
      body: cfop.objetoEncodeJson(cfop),
    );

    if (response.statusCode == 200) {
      if (response.headers["content-type"]!.contains("html")) {
        tratarRetornoErro(response.body, response.headers);
        return null;
      } else {
        var cfopJson = json.decode(response.body);
        return CfopModel.fromJson(cfopJson);
      }
    } else {
      tratarRetornoErro(response.body, response.headers);
      return null;
    }
  }

  Future<bool?> excluir(int id) async {
    final response = await clienteHTTP.delete(
      Uri.tryParse('$endpoint/cfop/$id')!,
      headers: {"content-type": "application/json"},
    );

    if (response.statusCode == 200) {
      return true;
    } else {
      tratarRetornoErro(response.body, response.headers);
      return null;
    }
  }  

  Future<CfopModel?> registrar(CfopModel cfop) async {
    final response = await clienteHTTP.post(
      Uri.tryParse('$endpoint/cfop/registro')!,
      headers: {
        "content-type": "application/json",
        },
      body: cfop.objetoEncodeJson(cfop),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.headers["content-type"]!.contains("html")) {
        tratarRetornoErro(response.body, response.headers);
        return null;
      } else {
        var cfopJson = json.decode(response.body);
        return CfopModel.fromJson(cfopJson);
      }
    } else {
      await tratarRetornoErro(response.body, response.headers);
      return null;
    }
  } 

  Future<CfopModel?> gravarDadosInformacao(CfopModel cfop) async {
    final response = await clienteHTTP.post(
      Uri.tryParse('$endpoint/cfop/grava-dados-informacao')!,
      headers: {
        "content-type": "application/json",
        },
      body: cfop.objetoEncodeJson(cfop),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.headers["content-type"]!.contains("html")) {
        tratarRetornoErro(response.body, response.headers);
        return null;
      } else {
        var cfopJson = json.decode(response.body);
        return CfopModel.fromJson(cfopJson);
      }
    } else {
      await tratarRetornoErro(response.body, response.headers);
      return null;
    }
  }   
}