/*
Title: T2Ti ERP 3.0                                                                
Description: Armazena os objetos para a sessão
                                                                                
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
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pegasus_pdv/src/model/model.dart';
import 'package:pegasus_pdv/src/service/cadastros/cfop_service.dart';

import 'package:pegasus_pdv/src/infra/biblioteca.dart';

import 'package:pegasus_pdv/src/model/retorno_json_erro.dart';
import 'package:pegasus_pdv/src/model/filtro.dart';

import 'package:pegasus_pdv/src/database/database.dart';
import 'package:pegasus_pdv/src/database/database_classes.dart';

import 'constantes.dart';

class Sessao {
  /// singleton
  factory Sessao() {
    _this ??= Sessao._();
    return _this!;
  }
  static Sessao? _this;
  Sessao._() : super();


// #region objetos globais
  static Filtro filtroGlobal = Filtro();
  static String tokenJWT = '';

  // objetos PDV
  static late AppDatabase db;

  static dynamic statusCaixa; 
  static bool abriuDialogBoxEspera = false;
  static late String retornoJsonLookup; // será usado para popular a grid da janela de lookup
  static String? retornoJsonNfce; //objeto retornado pelo ACBrMonitor
  static late String caminhoBancoDados; // guarda o caminho para o banco de dados
  static late String ultimoIniNfceEnviado; // guarda a string do último arquivo INI de NFC-e enviado para o ACBrMonitor
  static bool cnaePermiteModuloFood = false; // se for true, o sistema permite a utilização do módulo Food

  static PdvMovimento? movimento;
  static Empresa? empresa;
  static PdvConfiguracao? configuracaoPdv;
  static NfeConfiguracao? configuracaoNfce;
  static NfeNumero? numeroNfce;
  static NfcePlanoPagamento? nfcePlanoPagamento;
  static PdvVendaCabecalho? vendaAtual = PdvVendaCabecalho(id: null);
  static List<VendaDetalhe> listaVendaAtualDetalhe = [];
  static List<PdvTipoPagamento>? listaTipoPagamento = [];
  static List<Cfop>? listaCfop = [];
  static List<CfopModel>? listaCfopRemoto = [];
  static List<PdvTotalTipoPagamento> listaDadosPagamento = [];
  static List<ContasReceberMontado> listaParcelamento = []; // guarda o parcelamento atual da venda para ser impresso no recibo
  static RetornoJsonErro? objetoJsonErro; // objeto de erro estático que armazena o último erro ocorrido na aplicação
  
  /*
   [0] = codigo
   [1] = ex
   [2] = tipo
   [3] = descricao
   [4] = nacionalfederal
   [5] = importadosfederal
   [6] = estadual
   [7] = municipal
   [8] = vigenciainicio
   [9] = vigenciafim
   [10] = chave
   [11] = versao
   [12] = fonte
  */ 
  static late List<List<dynamic>> tabelaIbpt; // vamos carregar os dados do arquivo CSV

  /*
   [0] = ibge
   [1] = uf_sigla
   [2] = uf_codigo
   [3] = nome_caixa_alta
   [4] = nome_cursivo
   [5] = nome_sem_acento
   [6] = ddd
   [7] = siafi
  */ 
  static late List<List<dynamic>> tabelaMunicipios; // vamos carregar os dados do arquivo CSV

// #endregion objetos globais

  /// popula os objetos principais para a sessão
  static Future popularObjetosPrincipais(BuildContext context) async {
    db = Provider.of<AppDatabase>(context, listen: false);
    if (movimento == null) {
      await tratarMovimento();
    }    
    empresa = await db.empresaDao.consultarObjeto(1); // pega a empresa - deve ter apenas um registro no banco de dados
    // se o logo estiver nulo, insere um logo padrão e o usuário poderá alterar depois na tela de cadastro da empresa
    if (empresa!.logotipo == null) {
      final logotipo = (await rootBundle.load('assets/images/sua_logo.png')).buffer.asUint8List();
      empresa = empresa!.copyWith(
        logotipo: logotipo,
      );
      await db.empresaDao.alterar(Sessao.empresa!, false);
    }
    configuracaoPdv = await db.pdvConfiguracaoDao.consultarObjeto(1); // pega a configuracao - deve ter apenas um registro no banco de dados
    configuracaoNfce = await db.nfeConfiguracaoDao.consultarObjeto(1); // pega a configuracao da NFC-e - deve ter apenas um registro no banco de dados
    numeroNfce = await db.nfeNumeroDao.consultarObjeto(1); // pega o numero da nfc-e
    nfcePlanoPagamento = await db.nfcePlanoPagamentoDao.consultarPlanoAtivo(); 
    listaTipoPagamento = await db.pdvTipoPagamentoDao.consultarLista(); // pega os tipos de pagamento e poe numa lista

    // CFOP
    CfopService servico = CfopService();
    listaCfopRemoto = await (servico
        .consultarLista()); // pega os CFOPs do Servidor na Retaguarda e poe numa lista
    listaCfop = await db.cfopDao
        .consultarLista(); // pega os CFOPs do servidor local e poe numa lista
    if (listaCfopRemoto?.length != listaCfop?.length) {
      await popularCfopLocal(context);
    }

    // módulo Food
    final _listaCnae = await db.empresaCnaeDao.consultarLista();
    for (var cnae in _listaCnae) {
      if (cnae.codigo!.startsWith('56')) { // Alimentação
        cnaePermiteModuloFood = true;  
      }
    }

    final arquivoIbptCsv = await rootBundle.loadString('assets/text/ibpt.csv');
    tabelaIbpt = const CsvToListConverter().convert(arquivoIbptCsv, fieldDelimiter: ';');

    final arquivoMunicipiosCsv = await rootBundle.loadString('assets/text/municipios.csv');
    tabelaMunicipios = const CsvToListConverter().convert(arquivoMunicipiosCsv, fieldDelimiter: ';');

    if (kDebugMode && Biblioteca.isDesktop()) {
      await _gerarArquivoEnvProtegido();  
    }
  }

  /// popula os CFOP para a sessão
  static Future popularCfop(BuildContext context) async {
    listaCfop =
        await db.cfopDao.consultarLista(); // pega os CFOPs e poe numa lista
  }

  /// popula os CFOP no Banco de Dados Local
  static Future popularCfopLocal(BuildContext context) async {
    listaCfopRemoto?.forEach((element) async {
      Cfop cfop = Cfop.fromJson(element.toJson);
      await db.cfopDao.inserir(cfop);
    });
    listaCfop =
        await db.cfopDao.consultarLista(); // pega os CFOPs e poe numa lista
  }

  static void fecharDialogBoxEspera(BuildContext context) {
    Navigator.of(context).pop();
  }

  /// Passos:
  /// 01-busca um movimento com status = 'A' (aberto)
  /// 02-se não existir movimento, abre
  /// 03-se existir um movimento
  /// 03.1-verifica se o movimento é de outro dia
  /// 03.1.1 - se for um movimento de outro dia, encerra movimento e abre outro
  /// 03.1.2 - se for um movimento do mesmo dia, atribui para o movimento da sessão 
  static Future tratarMovimento() async {
    movimento = await db.pdvMovimentoDao.consultarObjeto('A'); 
    if (movimento == null) {
      movimento = PdvMovimento(id: null, dataAbertura: DateTime.now(), horaAbertura: Biblioteca.formatarHora(DateTime.now()), statusMovimento: 'A');
      movimento = await db.pdvMovimentoDao.iniciarMovimento(movimento!);
    } else {
      if (Biblioteca.formatarData(movimento!.dataAbertura) != Biblioteca.formatarData(DateTime.now())) {
        await db.pdvMovimentoDao.encerrarMovimento(movimento!);
        movimento = PdvMovimento(id: null, dataAbertura: DateTime.now(), horaAbertura: Biblioteca.formatarHora(DateTime.now()), statusMovimento: 'A');
        movimento = await db.pdvMovimentoDao.iniciarMovimento(movimento!);
      }
    }
  }

  static Future _gerarArquivoEnvProtegido() async {
    var conteudoEnvProtegido = '';

    conteudoEnvProtegido += 'SENTRY_DNS=' + Constantes.encrypter.encrypt(Constantes.sentryDns!, iv: Constantes.iv).base64 + '\n';
    conteudoEnvProtegido += 'LINGUAGEM_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.linguagemServidor!, iv: Constantes.iv).base64 + '\n';
    conteudoEnvProtegido += 'ENDERECO_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.enderecoServidor!, iv: Constantes.iv).base64 + '\n';
    if (Constantes.complementoEnderecoServidor!.isEmpty) {
      conteudoEnvProtegido += 'COMPLEMENTO_ENDERECO_SERVIDOR=\n';
    } else {
      conteudoEnvProtegido += 'COMPLEMENTO_ENDERECO_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.complementoEnderecoServidor!, iv: Constantes.iv).base64 + '\n';
    }
    conteudoEnvProtegido += 'PORTA_SERVIDOR=' + Constantes.encrypter.encrypt(Constantes.portaServidor!, iv: Constantes.iv).base64;

    final File file = File('.env-cifrado');
    await file.writeAsString(conteudoEnvProtegido);
  }


}