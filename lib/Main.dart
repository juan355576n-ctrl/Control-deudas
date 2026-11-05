import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const DeudasVerdeApp());
}

class DeudasVerdeApp extends StatelessWidget {
  const DeudasVerdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Control Financiero & Deudas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D0D), // Negro profundo
        primaryColor: const Color(0xFF00E676), // Verde brillante
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E676), // Verde
          secondary: Color(0xFFFFD700), // Dorado
          surface: Color(0xFF1A1A1A),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class Debt {
  String id;
  String name;
  double baseAmount;       // Monto base actual o inicial
  double overdueAmount;    // Monto viejo / vencido que ya venía acumulado
  double interestRate;     // Porcentaje de interés
  String frequency;        // 'Semanal', 'Quincenal', 'Mensual'
  DateTime lastDueDate;    // Próxima fecha de corte o vencimiento

  Debt({
    required this.id,
    required this.name,
    required this.baseAmount,
    required this.overdueAmount,
    required this.interestRate,
    required this.frequency,
    required this.lastDueDate,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'baseAmount': baseAmount,
        'overdueAmount': overdueAmount,
        'interestRate': interestRate,
        'frequency': frequency,
        'lastDueDate': lastDueDate.toIso8601String(),
      };

  factory Debt.fromJson(Map<String, dynamic> json) => Debt(
        id: json['id'],
        name: json['name'],
        baseAmount: json['baseAmount'],
        overdueAmount: json['overdueAmount'] ?? 0.0,
        interestRate: json['interestRate'],
        frequency: json['frequency'],
        lastDueDate: DateTime.parse(json['lastDueDate']),
      );

  // Calcula cuántos periodos vencidos han pasado desde la fecha de corte y aplica intereses
  CalculationResult calculateStatus() {
    final now = DateTime.now();
    final differenceDays = now.difference(lastDueDate).inDays;
    
    int periodsVencidos = 0;
    if (frequency == 'Semanal') {
      periodsVencidos = (differenceDays / 7).floor();
    } else if (frequency == 'Quincenal') {
      periodsVencidos = (differenceDays / 15).floor();
    } else if (frequency == 'Mensual') {
      periodsVencidos = (differenceDays / 30).floor();
    }

    if (periodsVencidos < 0) periodsVencidos = 0;

    // Si ya pasó al menos un periodo, calculamos el interés acumulado sobre el monto base
    double interestAccumulated = (baseAmount + overdueAmount) * (interestRate / 100) * periodsVencidos;
    double totalCurrent = baseAmount + overdueAmount + interestAccumulated;

    bool isVencido = now.isAfter(lastDueDate);

    return CalculationResult(
      total: totalCurrent,
      periodsOverdue: periodsVencidos,
      isOverdue: isVencido,
      daysLate: differenceDays > 0 ? differenceDays : 0,
    );
  }
}

class CalculationResult {
  double total;
  int periodsOverdue;
  bool isOverdue;
  int daysLate;

  CalculationResult({
    required this.total,
    required this.periodsOverdue,
    required this.isOverdue,
    required this.daysLate,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Debt> debts = [];

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? debtsString = prefs.getString('saved_green_debts');
    if (debtsString != null) {
      final List decoded = jsonDecode(debtsString);
      setState(() {
        debts = decoded.map((item) => Debt.fromJson(item)).toList();
      });
    }
  }

  Future<void> _saveDebts() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(debts.map((e) => e.toJson()).toList());
    await prefs.setString('saved_green_debts', encoded);
  }

  void _addDebtDialog() {
    final nameController = TextEditingController();
    final baseAmountController = TextEditingController();
    final overdueController = TextEditingController(text: '0');
    final rateController = TextEditingController();
    String selectedFrequency = 'Semanal';
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1A1A1A),
              title: const Text('Agregar Deuda / Crédito', style: TextStyle(color: Color(0xFFFFD700))),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre del deudor / Motivo', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    TextField(
                      controller: baseAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monto Principal Actual (\$)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    TextField(
                      controller: overdueController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Deuda Vieja / Monto Arrastrado (\$)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    TextField(
                      controller: rateController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Porcentaje de Interés (%)', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: selectedFrequency,
                      dropdownColor: const Color(0xFF262626),
                      items: ['Semanal', 'Quincenal', 'Mensual']
                          .map((freq) => DropdownMenuItem(value: freq, child: Text(freq)))
                          .toList(),
                      onChanged: (val) => selectedFrequency = val!,
                      decoration: const InputDecoration(labelText: 'Frecuencia de interés', labelStyle: TextStyle(color: Colors.white70)),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Fecha de Vencimiento / Corte:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        TextButton(
                          child: Text(
                            '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                            style: const TextStyle(color: Color(0xFF00E676), fontWeight: FontWeight.bold),
                          ),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E676),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    if (nameController.text.isNotEmpty && baseAmountController.text.isNotEmpty) {
                      setState(() {
                        debts.add(Debt(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          baseAmount: double.parse(baseAmountController.text),
                          overdueAmount: double.tryParse(overdueController.text) ?? 0.0,
                          interestRate: double.tryParse(rateController.text) ?? 0.0,
                          frequency: selectedFrequency,
                          lastDueDate: selectedDate,
                        ));
                      });
                      _saveDebts();
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    double totalGeneral = 0;
    int totalVencidas = 0;

    for (var debt in debts) {
      var res = debt.calculateStatus();
      totalGeneral += res.total;
      if (res.isOverdue) totalVencidas++;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control Financiero', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Tarjeta de Resumen con Verde, Negro y Dorado
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003311), Color(0xFF111111)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL GLOBAL ACUMULADO', style: TextStyle(fontSize: 11, color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('$totalVencidas deudas con alerta de vencimiento', style: const TextStyle(fontSize: 11, color: Colors.white60)),
                  ],
                ),
                Text(
                  '\$${totalGeneral.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF00E676)),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Deudas y Acumulados Activos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: debts.isEmpty
                ? const Center(
                    child: Text('No hay registros guardados.', style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    itemCount: debts.length,
                    itemBuilder: (context, index) {
                      final debt = debts[index];
                      final status = debt.calculateStatus();

                      return Card(
                        color: const Color(0xFF1A1A1A),
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: status.isOverdue ? Colors.redAccent.withOpacity(0.6) : Colors.white12,
                            width: status.isOverdue ? 1.5 : 1,
                          ),
                        ),
                        child: ListTile(
                          title: Text(debt.name, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                'Base: \$${debt.baseAmount.toStringAsFixed(2)} + Viejas: \$${debt.overdueAmount.toStringAsFixed(2)} | ${debt.interestRate}% (${debt.frequency})',
                                style: const TextStyle(color: Colors.white60, fontSize: 11),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                status.isOverdue
                                    ? '⚠️ Vencido hace ${status.daysLate} días (${status.periodsOverdue} periodos)'
                                    : 'Al día (Corte: ${debt.lastDueDate.day}/${debt.lastDueDate.month})',
                                style: TextStyle(
                                  color: status.isOverdue ? Colors.redAccent : const Color(0xFF00E676),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${status.total.toStringAsFixed(2)}',
                                style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const Text('Total Actual', style: TextStyle(color: Colors.white54, fontSize: 9)),
                            ],
                          ),
                          onLongPress: () {
                            setState(() {
                              debts.removeAt(index);
                            });
                            _saveDebts();
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00E676),
        foregroundColor: Colors.black,
        onPressed: _addDebtDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
