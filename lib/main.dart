import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

void main() {
  runApp(MaterialApp(
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {

  final _toDoControler = TextEditingController();

  List _toDoList = [];
  late Map<String, dynamic> _lastRemoved;
  late int _lastRemovedPos;

  //O initState é chamado quando inicializamos o app. Vamos reescrever essa função para que ela busque os dados salvos do json
  @override
  void initState() {
    super.initState();
    //_readData() não puxa os valores na mesma hora, então usamos o .then
    _readData().then((data){ //A string retornada pelo _readData é passada para data
      setState(() {
        _toDoList = json.decode(data!);
      });
    });
  }

  void _addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = Map();
      newToDo["title"] = _toDoControler.text;
      _toDoControler.text = "";
      newToDo["ok"] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1)); //Timer de 1 segundo
    setState(() {
      _toDoList.sort((a, b){
        if(a["ok"] && !b["ok"]) return 1;
        else if(!a["ok"] && b["ok"]) return -1;
        else return 0;
      });
      _saveData();
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lista de Tarefas"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
              padding: EdgeInsets.fromLTRB(17, 1, 7, 1),
              child: Row(
                children: [
                  //É necessário usar o Expanded para que o app saiba o tamanho que o TextFiel deve ocupar
                  //caso contrário ele terá tamanho infinito e não funcionará
                  Expanded(
                      child: TextField(
                        controller: _toDoControler,
                        decoration: InputDecoration(
                        labelText: "Nova Tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)),
                  )),
                  ElevatedButton(
                    onPressed: _addToDo,
                    style: ButtonStyle(
                      backgroundColor:
                          MaterialStateProperty.all<Color>(Colors.blueAccent),
                    ),
                    child: Text(
                      "+",
                      style: TextStyle(color: Colors.white, fontSize: 20.0),
                    ),
                  ),
                ],
              )),
          Expanded(
            child: RefreshIndicator(
              child: ListView.builder(
                //ListView é um widget pra fazer uma lista
                //O .builder irá permitir que lista seja construída a medida que rolamos ela, ou seja, ele não renderiza o que não está sendo mostrado na tela
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem
              ),
              onRefresh: _refresh,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index){
    return Dismissible( //Cria o widget que arrasta para o lado
      background: Container( //O que estará por trás do widget quandp ele for arrastado
        color: Colors.red,
        child: Align( //Para colocar o ícone da lixeira no canto esquerdo
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete, color: Colors.white),
        )
      ),
      direction: DismissDirection.startToEnd,
      //A key serve pra saber qual elemento está sendo deslizado para o lado e ele deve ser diferente para cada item da lista, entao vamos usar o tempo atual em ms (não é a melhor forma)
      key: Key(DateTime.now().microsecondsSinceEpoch.toString()),
      child: CheckboxListTile( //No child colocamos onde será aplicado esse Dismissible
        value: _toDoList[index]["ok"],
        onChanged: (bool? value){ //O valor passado aqui é a condição atual da checkbox. O parâmetro passado já recebe esse valor mesmo você nunca tendo criado
          setState(() {
            _toDoList[index]["ok"] = value;
            _saveData();
          });
        },
        title: Text(_toDoList[index]["title"]),
        secondary: CircleAvatar(
          child: Icon(_toDoList[index]["ok"]? Icons.check : Icons.error),
        ),
      ),
      onDismissed: (direction){ //Pega a direção para onde deslizou o item, mas nesse caso a direção é única e então nem usaremos a variável
        setState(() {
          _lastRemoved = Map.from(_toDoList[index]);
          _lastRemovedPos = index;
          _toDoList.removeAt(index);

          _saveData();

          final snack = SnackBar(
            content: Text("Tarefa \"${_lastRemoved["title"]}\" removida"),
            action: SnackBarAction(
              label: "Desfazer",
              onPressed: (){
                setState(() {
                  _toDoList.insert(_lastRemovedPos, _lastRemoved);
                  _saveData();
                });
              },
            ),
            duration: Duration(seconds: 3),
          );
          ScaffoldMessenger.of(context).showSnackBar(snack); //Exibe o snack
        });
      },
    );
  }

  /*
  Tudo o que envolve leitura e escrita em arquivos não ocorre no mesmo instante,
  por conta disso usamos as funções como async, uma vez que utilizaremos também
  o await por conta do retorno de um Future
  */

  //Função para pegar o arquivo que iremos utilizar para armazenar os dados
  Future<File> _getFile() async {
    //A biblioteca path_provider nos permite puxar o path de onde podemos armazenar o nosso json com os dados
    //Como o path é diferente de acordo com o SO e existe uma questão de permissões, usar função getApplicationDocumentsDirectory() é a melhor opção
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  //Função para salvar os dados
  Future<File> _saveData() async {
    String data = json.encode(
        _toDoList); //Transforma nossa listaem um json para ser armazenado
    final file = await _getFile(); //Obtém o arquivo onde armmazenasmos os dados
    return file.writeAsString(data); //Escreve no arquivo que foi obtido
  }

  //FUnção para ler os dados
  Future<String?> _readData() async {
    try {
      final file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}
