import 'package:flutter/material.dart';

class Calculatrice extends StatefulWidget {
  @override
  _CalculatriceState createState() => _CalculatriceState();
}

class _CalculatriceState extends State<Calculatrice> {
  String _output = "0"; // Affichage actuel
  double _num1 = 0.0; // Premier nombre
  double _num2 = 0.0; // Deuxième nombre
  String _operand = ""; // Opérateur (+, -, *, /)
  String _operation = ""; // Opération en cours (ex: "5 + 3")

  void _buttonPressed(String buttonText) {
    if (buttonText == "C") {
      // Réinitialiser la calculatrice
      setState(() {
        _output = "0";
        _num1 = 0.0;
        _num2 = 0.0;
        _operand = "";
        _operation = ""; // Réinitialiser l'opération en cours
      });
    } else if (buttonText == "+" || buttonText == "-" || buttonText == "*" || buttonText == "/") {
      // Enregistrer le premier nombre et l'opérateur
      setState(() {
        _num1 = double.parse(_output);
        _operand = buttonText;
        _operation = "$_output $buttonText"; // Afficher l'opération en cours
        _output = "0";
      });
    } else if (buttonText == "=") {
      // Effectuer le calcul
      setState(() {
        _num2 = double.parse(_output);
        if (_operand == "+") {
          _output = (_num1 + _num2).toString();
        }
        if (_operand == "-") {
          _output = (_num1 - _num2).toString();
        }
        if (_operand == "*") {
          _output = (_num1 * _num2).toString();
        }
        if (_operand == "/") {
          _output = (_num1 / _num2).toString();
        }
        _operation = "$_num1 $_operand $_num2 = $_output"; // Afficher l'opération complète
        _num1 = 0.0;
        _num2 = 0.0;
        _operand = "";
      });
    } else {
      // Ajouter un chiffre ou une décimale
      setState(() {
        if (_output == "0") {
          _output = buttonText;
        } else {
          _output += buttonText;
        }
        _operation = "$_num1 $_operand $_output"; // Mettre à jour l'opération en cours
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 1, // Occupe 1 partie de l'espace disponible
          child: Container(
            padding: EdgeInsets.all(16.0),
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Fait défiler vers la droite
                    child: Text(
                      _operation, // Afficher l'opération en cours
                      style: TextStyle(fontSize: 24.0, color: Colors.grey),
                    ),
                  ),
                ),
                SizedBox(height: 8.0),
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    reverse: true, // Fait défiler vers la droite
                    child: Text(
                      _output, // Afficher le résultat actuel
                      style: TextStyle(fontSize: 48.0, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        Divider(height: 1.0),
        Expanded(
          flex: 3, // Occupe 4 parties de l'espace disponible
          child: GridView.count(
            crossAxisCount: 4,
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
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButton(String buttonText) {
    return Container(
      margin: EdgeInsets.all(8.0),
      child: ElevatedButton(
        onPressed: () => _buttonPressed(buttonText),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue.shade800,
          padding: EdgeInsets.all(24.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: Text(
          buttonText,
          style: TextStyle(fontSize: 24.0, color: Colors.white),
        ),
      ),
    );
  }
}