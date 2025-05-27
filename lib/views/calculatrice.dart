import 'package:flutter/material.dart';

class Calculatrice extends StatefulWidget {
  @override
  _CalculatriceState createState() => _CalculatriceState();
}

class _CalculatriceState extends State<Calculatrice> {
  String _output = "0";
  double _num1 = 0.0;
  double _num2 = 0.0;
  String _operand = "";
  String _operation = "";
  List<String> _history = [];

  void _buttonPressed(String buttonText) {
    if (buttonText == "C") {
      setState(() {
        if (_output.length > 1) {
          _output = _output.substring(0, _output.length - 1);
        } else {
          _output = "0";
        }
        _operation = "$_num1 $_operand $_output";
      });
    } else if (buttonText == "AC") {
      setState(() {
        _history.clear();
      });
    } else if (buttonText == "+" ||
        buttonText == "-" ||
        buttonText == "*" ||
        buttonText == "/") {
      setState(() {
        _num1 = double.tryParse(_output) ?? 0.0;
        _operand = buttonText;
        _operation = "$_output $buttonText";
        _output = "0";
      });
    } else if (buttonText == "=") {
      setState(() {
        _num2 = double.tryParse(_output) ?? 0.0;
        double result = 0.0;
        if (_operand == "+") result = _num1 + _num2;
        if (_operand == "-") result = _num1 - _num2;
        if (_operand == "*") result = _num1 * _num2;
        if (_operand == "/") result = _num2 != 0 ? _num1 / _num2 : 0;

        if (result == result.toInt()) {
          _output = result
              .toInt()
              .toString(); // Affiche sans décimales si c’est entier
        } else {
          _output = result.toString(); // Sinon affiche avec décimales
        }

        String fullOperation = "$_num1 $_operand $_num2 = $_output";
        _history.add(fullOperation);
        _operation = fullOperation;

        _num1 = 0.0;
        _num2 = 0.0;
        _operand = "";
      });
    } else {
      setState(() {
        if (_output == "0") {
          _output = buttonText;
        } else {
          _output += buttonText;
        }
        _operation = "$_num1 $_operand $_output";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculatrice', 
        style: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,)),
        backgroundColor: Colors.blueAccent,
        elevation: 8,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            tooltip: "Vider l'historique",
            onPressed: () {
              setState(() {
                _history.clear();
              });
            },
          )
        ],
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            // Historique
            if (_history.isNotEmpty)
              Container(
                height: 100,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  reverse: true,
                  itemCount: _history.length,
                  itemBuilder: (context, index) {
                    return Text(
                      _history[_history.length - 1 - index],
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    );
                  },
                ),
              ),
            const Divider(),
            // Opération et résultat
            Container(
              padding: const EdgeInsets.all(16),
              alignment: Alignment.bottomRight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _operation,
                      style: const TextStyle(fontSize: 24, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    child: Text(
                      _output,
                      style:
                          const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Boutons
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                padding: const EdgeInsets.all(8),
                children: [
                  _buildButton("7"),
                  _buildButton("8"),
                  _buildButton("9"),
                  _buildButton("/"),
                  _buildButton("4"),
                  _buildButton("5"),
                  _buildButton("6"),
                  _buildButton("*"),
                  _buildButton("1"),
                  _buildButton("2"),
                  _buildButton("3"),
                  _buildButton("-"),
                  _buildButton("."),
                  _buildButton("0"),
                  _buildButton("C"),
                  _buildButton("+"),
                  _buildButton("="),
                  _buildButton("AC"), // Pour vider l'historique
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(String buttonText) {
    return Container(
      margin: const EdgeInsets.all(6.0),
      child: ElevatedButton(
        onPressed: () => _buttonPressed(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonText == "="
              ? Colors.green
              : buttonText == "C" || buttonText == "AC"
                  ? Colors.red
                  : Colors.blueAccent,
          padding: const EdgeInsets.all(20.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            buttonText,
            style: const TextStyle(fontSize: 24.0, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
