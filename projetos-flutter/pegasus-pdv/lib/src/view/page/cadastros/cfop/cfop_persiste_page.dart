/*
Title: T2Ti ERP 3.0                                                                
Description: PersistePage relacionada à tabela [CFOP] 
                                                                                
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

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bootstrap/flutter_bootstrap.dart';
import 'package:pegasus_pdv/src/database/database_classes.dart';

import 'package:pegasus_pdv/src/infra/infra.dart';
import 'package:pegasus_pdv/src/infra/atalhos_desktop_web.dart';
import 'package:pegasus_pdv/src/model/model.dart';
import 'package:pegasus_pdv/src/service/service.dart';

import 'package:pegasus_pdv/src/view/shared/view_util_lib.dart';
import 'package:pegasus_pdv/src/view/shared/caixas_de_dialogo.dart';
import 'package:pegasus_pdv/src/view/shared/botoes.dart';
import 'package:pegasus_pdv/src/view/shared/widgets_input.dart';

class CfopPersistePage extends StatefulWidget {
  final Cfop? cfop;
  final String? title;
  final String? operacao;

  const CfopPersistePage({Key? key, this.cfop, this.title, this.operacao})
      : super(key: key);

  @override
  _CfopPersistePageState createState() => _CfopPersistePageState();
}

class _CfopPersistePageState extends State<CfopPersistePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  AutovalidateMode _autoValidate = AutovalidateMode.disabled;
  bool _formFoiAlterado = false;
  CfopService servico = CfopService();

  Map<LogicalKeySet, Intent>? _shortcutMap;
  Map<Type, Action<Intent>>? _actionMap;
  final _foco = FocusNode();

  Cfop? cfop;

  @override
  void initState() {
    super.initState();
    bootstrapGridParameters(
      gutterSize: Constantes.flutterBootstrapGutterSize,
    );

    _shortcutMap = getAtalhosPersistePage();

    _actionMap = <Type, Action<Intent>>{
      AtalhoTelaIntent: CallbackAction<AtalhoTelaIntent>(
        onInvoke: _tratarAcoesAtalhos,
      ),
    };
    cfop = widget.cfop;
    _foco.requestFocus();
  }

  void _tratarAcoesAtalhos(AtalhoTelaIntent intent) {
    switch (intent.type) {
      case AtalhoTelaType.excluir:
        _excluir();
        break;
      case AtalhoTelaType.salvar:
        _salvar();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      actions: _actionMap,
      shortcuts: _shortcutMap,
      child: Focus(
        autofocus: true,
        child: Scaffold(
          drawerDragStartBehavior: DragStartBehavior.down,
          key: _scaffoldKey,
          appBar: AppBar(
            title: Text(widget.title!),
            actions: widget.operacao == 'I'
                ? getBotoesAppBarPersistePage(
                    context: context,
                    salvar: _salvar,
                  )
                : getBotoesAppBarPersistePageComExclusao(
                    context: context, salvar: _salvar, excluir: _excluir),
          ),
          body: SafeArea(
            top: false,
            bottom: false,
            child: Form(
              key: _formKey,
              autovalidateMode: _autoValidate,
              onWillPop: _avisarUsuarioFormAlterado,
              child: Scrollbar(
                child: SingleChildScrollView(
                  dragStartBehavior: DragStartBehavior.down,
                  child: BootstrapContainer(
                    fluid: true,
                    decoration: const BoxDecoration(color: Colors.white),
                    padding: Biblioteca.isTelaPequena(context) == true
                        ? ViewUtilLib.paddingBootstrapContainerTelaPequena
                        : ViewUtilLib
                            .paddingBootstrapContainerTelaGrande, // children: [
                    children: <Widget>[
                      const Divider(
                        color: Colors.white,
                      ),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: TextFormField(
                              focusNode: _foco,
                              validator:
                                  ValidaCampoFormulario.validarObrigatorio,
                              maxLength: 3,
                              maxLines: 1,
                              initialValue: '${cfop?.codigo ?? ''}',
                              decoration: getInputDecoration(
                                  'Conteúdo para o campo Codigo',
                                  'Codigo',
                                  false),
                              onSaved: (String? value) {},
                              onChanged: (text) {
                                cfop = cfop!.copyWith(codigo: int.parse(text));
                                _formFoiAlterado = true;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.white,
                      ),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: TextFormField(
                              validator:
                                  ValidaCampoFormulario.validarObrigatorio,
                              maxLength: 1000,
                              maxLines: 6,
                              initialValue: cfop?.descricao ?? '',
                              decoration: getInputDecoration(
                                  'Conteúdo para o campo Descricao',
                                  'Descricao',
                                  false),
                              onSaved: (String? value) {},
                              onChanged: (text) {
                                cfop = cfop!.copyWith(descricao: text);
                                _formFoiAlterado = true;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.white,
                      ),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: TextFormField(
                              validator:
                                  ValidaCampoFormulario.validarObrigatorio,
                              maxLength: 1000,
                              maxLines: 6,
                              initialValue: cfop?.aplicacao ?? '',
                              decoration: getInputDecoration(
                                  'Conteúdo para o campo Aplicacao',
                                  'Aplicacao',
                                  false),
                              onSaved: (String? value) {},
                              onChanged: (text) {
                                cfop = cfop!.copyWith(aplicacao: text);
                                _formFoiAlterado = true;
                              },
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.white,
                      ),
                      BootstrapRow(
                        height: 60,
                        children: <BootstrapCol>[
                          BootstrapCol(
                            sizes: 'col-12',
                            child: Text(
                              '* indica que o campo é obrigatório',
                              style: Theme.of(context).textTheme.caption,
                            ),
                          ),
                        ],
                      ),
                      const Divider(
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<bool> _salvarDadosRemotos() async {
    CfopModel? model = CfopModel.fromDB(cfop!);
    bool tudoCerto = false;
    gerarDialogBoxEspera(context);
    if (widget.operacao == 'A') {
      final resCfop = await (servico.alterar(model));
      if (resCfop != null) {
        tudoCerto = true;
      }
    } else {
      final resCfop = await (servico.inserir(model));
      if (resCfop != null) {
        tudoCerto = true;
      }
    }
    Sessao.fecharDialogBoxEspera(context);
    if (tudoCerto != null) {
      return true;
    } else {
      showInSnackBar(
          'Ocorreu um problema ao tentar salvar os dados da empresa no Servidor.',
          context,
          corFundo: Colors.red);
      return false;
    }
  }

  Future<void> _salvar() async {
    final FormState form = _formKey.currentState!;
    if (!form.validate()) {
      _autoValidate = AutovalidateMode.always;
      showInSnackBar(Constantes.mensagemCorrijaErrosFormSalvar, context);
    } else {
      gerarDialogBoxConfirmacao(context, Constantes.perguntaSalvarAlteracoes,
          () async {
        form.save();
        bool tudoCerto = false;
        final saveServer = await _salvarDadosRemotos();
        if (saveServer) {
          if (widget.operacao == 'A') {
            await Sessao.db.cfopDao.alterar(cfop!);
            tudoCerto = true;
          } else {
            final numCfop = await Sessao.db.cfopDao
                .consultarObjetoFiltro('CODIGO', '${cfop!.codigo!}');
            if (numCfop == null) {
              await Sessao.db.cfopDao.inserir(cfop!);
              tudoCerto = true;
            } else {
              showInSnackBar(
                  'Já existe um cfop cadastrado com o CÓDIGO informado.',
                  context);
            }
          }
        }
        if (tudoCerto) {
          await Sessao.popularCfop(context);
          Navigator.of(context).pop();
        }
      });
    }
  }

  Future<bool> _avisarUsuarioFormAlterado() async {
    final FormState? form = _formKey.currentState;
    if (form == null || !_formFoiAlterado) {
      return true;
    } else {
      await (gerarDialogBoxFormAlterado(context));
      return false;
    }
  }

  void _excluir() {
    gerarDialogBoxExclusao(context, () async {
      await servico.excluir(cfop!.id!);
      await Sessao.db.cfopDao.excluir(cfop!);
      Navigator.of(context).pop();
    });
  }
}
