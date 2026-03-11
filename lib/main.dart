import 'package:flutter/material.dart';

void main() {
  runApp(const RayRideApp());
}

class RayRideApp extends StatelessWidget {
  const RayRideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RayRide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF151B2D), // Deep dark blue background
        primaryColor: const Color(0xFFF27A22), // Orange
        fontFamily: 'Roboto',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF27A22),
          secondary: Color(0xFFF27A22),
          surface: Color(0xFF1E2742), // Lighter blue for cards
        ),
      ),
      home: const SignInScreen(),
    );
  }
}

// ================== 1. SIGN IN SCREEN ==================
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2C3E66), Color(0xFF151B2D)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.directions_car_filled, size: 60, color: Color(0xFFF27A22)),
                const SizedBox(height: 16),
                const Text(
                  'RayRide',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 40),
                _buildTextField('Email', Icons.email_outlined),
                const SizedBox(height: 16),
                _buildTextField('Password', Icons.lock_outline, isPassword: true),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27A22),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Sign In', style: TextStyle(fontSize: 18, color: Colors.white)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const SignUpScreen()));
                  },
                  child: const Text('Create Account', style: TextStyle(color: Colors.white70)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E2742),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// ================== 2. SIGN UP SCREEN ==================
class SignUpScreen extends StatelessWidget {
  const SignUpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      backgroundColor: const Color(0xFF151B2D),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Join RayRide',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 30),
            _buildTextField('Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField('Email', Icons.email_outlined),
            const SizedBox(height: 16),
            _buildTextField('Password', Icons.lock_outline, isPassword: true),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                      context, MaterialPageRoute(builder: (context) => const MainScreen()));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27A22),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sign Up', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, IconData icon, {bool isPassword = false}) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: const Color(0xFF1E2742),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}

// ================== 3. MAIN SCREEN (Booking) ==================
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  String selectedPickup = "Antalya Airport (AYT)";
  String selectedDropoff = "Belek Hotel Zone";
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 30);

  final List<String> locations = [
    "Antalya Airport (AYT)",
    "Belek Hotel Zone",
    "Kaleici Old Town",
    "Lara Beach Hotels",
    "Konyaalti Beach",
    "Side Town Center",
    "Alanya Marina",
    "Kemer Resort Area",
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF27A22),
              onPrimary: Colors.white,
              surface: Color(0xFF2C3E66),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E2742),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF27A22),
              onPrimary: Colors.white,
              surface: Color(0xFF2C3E66),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E2742),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Color(0xFFBA5A2B), Color(0xFF151B2D)],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.directions_car_filled, color: Colors.white),
                          SizedBox(width: 8),
                          Text('RayRide', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                              );
                            },
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_none, color: Colors.white, size: 28),
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                    child: const Text('2', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                            },
                            child: const CircleAvatar(
                              radius: 18,
                              backgroundColor: Color(0xFFF27A22),
                              child: Icon(Icons.person, color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text('Hoş Geldiniz! ☀️', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 14)),
                  const SizedBox(height: 5),
                  const Text('Where would you\nlike to go?',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
                  const SizedBox(height: 5),
                  const Text('Premium transfers across the Turkish Riviera', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 25),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2742),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.centerRight,
                          children: [
                            Column(
                              children: [
                                _buildLocationRow(
                                  Icons.flight_takeoff,
                                  "PICK-UP",
                                  selectedPickup,
                                  onTap: () => _showLocationPicker(
                                    title: "Select Pick-up Location",
                                    currentValue: selectedPickup,
                                    icon: Icons.flight_takeoff,
                                    onSelected: (val) => setState(() => selectedPickup = val),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 11),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Container(width: 1, height: 20, color: Colors.white24),
                                  ),
                                ),
                                _buildLocationRow(
                                  Icons.location_on,
                                  "DROP-OFF",
                                  selectedDropoff,
                                  onTap: () => _showLocationPicker(
                                    title: "Select Drop-off Location",
                                    currentValue: selectedDropoff,
                                    icon: Icons.location_on,
                                    onSelected: (val) => setState(() => selectedDropoff = val),
                                  ),
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  final temp = selectedPickup;
                                  selectedPickup = selectedDropoff;
                                  selectedDropoff = temp;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C3655),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.white10),
                                ),
                                child: const Icon(Icons.swap_vert, color: Color(0xFFF27A22)),
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: _buildInputBox(
                                Icons.calendar_today,
                                "DATE",
                                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                onTap: () => _selectDate(context),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildInputBox(
                                Icons.access_time,
                                "TIME",
                                selectedTime.format(context),
                                onTap: () => _selectTime(context),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChooseRideScreen(
                                    pickup: selectedPickup,
                                    dropoff: selectedDropoff,
                                    date: "${selectedDate.day} Feb",
                                    time: selectedTime.format(context),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.search, color: Colors.white),
                            label: const Text('Find Transfers', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF27A22),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),


                  ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ToursScreen())),
                    icon: const Icon(Icons.tour, color: Colors.white),
                    label: const Text('View Day-Trip Tours', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF27A22),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),


                  const SizedBox(height: 30),
                  const Text('Popular Routes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),




                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildRouteCard("Airport", "Belek", "€35", "~30 min", "VIP Vito", Icons.airport_shuttle),
                        _buildRouteCard("Airport", "Kaleiçi", "€20", "~20 min", "Economy", Icons.directions_car),
                        _buildRouteCard("Airport", "Kemer", "€50", "~55 min", "Comfort", Icons.directions_bus),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLocationPicker({
    required String title,
    required String currentValue,
    required IconData icon,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2C3E66),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  itemCount: locations.length,
                  itemBuilder: (context, index) {
                    final location = locations[index];
                    final isSelected = location == currentValue;
                    return ListTile(
                      leading: Icon(
                        icon,
                        color: isSelected ? const Color(0xFFF27A22) : Colors.white54,
                      ),
                      title: Text(
                        location,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFFF27A22) : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Color(0xFFF27A22))
                          : null,
                      onTap: () {
                        onSelected(location);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF27A22), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox(IconData icon, String label, String value, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF151B2D),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFF27A22), size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(String from, String to, String price, String time, String type, IconData icon) {
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2742),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(from, style: const TextStyle(color: Color(0xFFF27A22), fontSize: 12)),
            const Icon(Icons.arrow_right_alt, color: Colors.white54, size: 16),
            Text(to, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(6)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 12, color: Colors.white70),
                const SizedBox(width: 4),
                Text(type, style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ],
            ),
          )
        ],
      ),
    );
  }
}


void showLanguageDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF1E2742),
      title: const Text('Select Language', style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(title: const Text('🇬🇧 English', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('🇹🇷 Türkçe', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('🇸🇾 العربية', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
          ListTile(title: const Text('🇷🇺 Русский', style: TextStyle(color: Colors.white)), onTap: () => Navigator.pop(context)),
        ],
      ),
    ),
  );
}




// ================== 4. PROFILE SCREEN ==================
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined))
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 40,
                    backgroundColor: Color(0xFFF27A22),
                    child: Text('AT', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  const SizedBox(height: 16),
                  const Text('Alex Thompson', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                  const Text('alex.thompson@email.com', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFFD700)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                        SizedBox(width: 4),
                        Text('Gold Member', style: TextStyle(color: Color(0xFFFFD700), fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatItem('12', 'Trips'),
                      Container(width: 1, height: 30, color: Colors.white12),
                      _buildStatItem('4.9', 'Rating'),
                      Container(width: 1, height: 30, color: Colors.white12),
                      _buildStatItem('€340', 'Saved'),
                    ],
                  ),

                  const SizedBox(height: 30),

                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2742),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(Icons.history, 'Booking History'),
                        const Divider(color: Colors.white10, height: 1),
                        _buildMenuItem(Icons.credit_card, 'Payment Methods', subtitle: 'Visa **** 4242'),
                        const Divider(color: Colors.white10, height: 1),
                        _buildMenuItem(Icons.favorite_border, 'Saved Routes', subtitle: '3 saved routes'),
                        const Divider(color: Colors.white10, height: 1),
                        _buildMenuItem(Icons.translate, 'Language', subtitle: 'English', onTap: () => showLanguageDialog(context)),
                        const Divider(color: Colors.white10, height: 1),
                        _buildMenuItem(Icons.help_outline, 'Help & Support'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  const Align(alignment: Alignment.centerLeft, child: Text('Recent Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white))),
                  const SizedBox(height: 16),

                  _buildTripItem("Airport → Belek", "20 Feb", "€35"),
                  const SizedBox(height: 10),
                  _buildTripItem("Belek → Kaleici", "18 Feb", "€28"),
                  const SizedBox(height: 10),
                  _buildTripItem("Airport → Lara", "15 Feb", "€22"),

                  const SizedBox(height: 40),

                  // LOGOUT BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const SignInScreen()),
                              (Route<dynamic> route) => false,
                        );
                      },
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.redAccent, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
      ],
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {String? subtitle, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: const Color(0xFFF27A22), size: 20),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)) : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.white38, size: 20),
      onTap: onTap ?? () {},
    );
  }

  Widget _buildTripItem(String route, String date, String price) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2742),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.directions_car, color: Colors.white70, size: 16),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                  Text(date, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ],
          ),
          Text(price, style: const TextStyle(color: Color(0xFFF27A22), fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }
}

class ChooseRideScreen extends StatelessWidget {
  final String pickup;
  final String dropoff;
  final String date;
  final String time;

  const ChooseRideScreen({
    super.key,
    required this.pickup,
    required this.dropoff,
    required this.date,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Choose Your Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 8, bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(20)),
              child: const Row(
                children: [
                  Icon(Icons.sort, color: Color(0xFFF27A22), size: 16),
                  SizedBox(width: 4),
                  Text('Sort', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.flight_takeoff, color: Color(0xFFF27A22), size: 16),
                        const SizedBox(width: 8),
                        Text(pickup, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 7, top: 4, bottom: 4),
                      height: 10,
                      width: 1,
                      color: Colors.white24,
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Color(0xFFF27A22), size: 16),
                        const SizedBox(width: 8),
                        Text(dropoff, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 12),
                    Text(time, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                )
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildVehicleCard(
                  context,
                  name: 'Economy Sedan',
                  subtitle: 'Toyota Corolla or similar',
                  price: '€25.00',
                  time: '~25 min',
                  pax: 3,
                  bags: 2,
                  isVip: false,
                  imagePath: 'assets/toytaCorolla0.png',
                ),
                _buildVehicleCard(
                  context,
                  name: 'Comfort Plus',
                  subtitle: 'Mercedes E-Class',
                  price: '€38.00',
                  time: '~25 min',
                  pax: 3,
                  bags: 3,
                  isVip: false,
                  imagePath: 'assets/classs.png',
                ),
                _buildVehicleCard(
                  context,
                  name: 'VIP Vito',
                  subtitle: 'Mercedes-Benz Vito',
                  price: '€55.00',
                  time: '~25 min',
                  pax: 6,
                  bags: 6,
                  isVip: true,
                  imagePath: 'assets/vito.png',
                ),
                _buildVehicleCard(
                  context,
                  name: 'Mercedes Sprinter',
                  subtitle: 'VIP Group Shuttle',
                  price: '€75.00',
                  time: '~30 min',
                  pax: 12,
                  bags: 12,
                  isVip: true,
                  imagePath: 'assets/sprinter7.png',
                ),
                _buildVehicleCard(
                  context,
                  name: 'Cadillac Escalade',
                  subtitle: 'Premium Luxury SUV',
                  price: '€90.00',
                  time: '~25 min',
                  pax: 4,
                  bags: 4,
                  isVip: true,
                  imagePath: 'assets/cadil5.png',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(
      BuildContext context, {
        required String name,
        required String subtitle,
        required String price,
        required String time,
        required int pax,
        required int bags,
        required bool isVip,
        required String imagePath,
      }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isVip ? const Color(0xFF3B2A2E) : const Color(0xFF1E2742), // Brownish for VIP, Blue for standard
        borderRadius: BorderRadius.circular(16),
        border: isVip ? Border.all(color: Colors.orangeAccent.withOpacity(0.2)) : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        if (isVip) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: const Color(0xFFF27A22), borderRadius: BorderRadius.circular(4)),
                            child: const Text('VIP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                          )
                        ]
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price, style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(time, style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  ],
                )
              ],
            ),

            // Placeholder for Car Image
            // Replace the old Container with this:
            Container(
              height: 100,
              width: double.infinity,
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: Image.asset(imagePath, fit: BoxFit.contain),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildFeatureChip(Icons.person, '$pax pax'),
                    const SizedBox(width: 8),
                    _buildFeatureChip(Icons.work, '$bags bags'),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ConfirmBookingScreen(
                          vehicleName: name,
                          vehicleSubtitle: subtitle,
                          price: price,
                          imagePath: imagePath,
                          pickup: pickup, // Passed from ChooseRideScreen
                          dropoff: dropoff, // Passed from ChooseRideScreen
                          date: date, // Passed from ChooseRideScreen
                          time: time, // Passed from ChooseRideScreen
                          pax: pax.toString(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27A22),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Select', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 14),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String selectedFilter = 'All';

  final List<Map<String, dynamic>> notifications = [
    {
      'title': 'Booking Confirmed',
      'message': 'Your VIP Vito transfer from Airport to Belek on 25 Feb at 14:30 is confirmed. Driver details will be sent 1 hour before pickup.',
      'time': '2 min ago',
      'category': 'Bookings',
      'isUnread': true,
      'icon': Icons.check,
      'iconColor': Colors.greenAccent,
      'iconBg': Colors.green.withOpacity(0.2),
    },
    {
      'title': '20% Off Your Next Ride!',
      'message': 'Welcome to Antalya! Enjoy 20% discount on your next transfer. Use code: WELCOME20',
      'time': '1 hour ago',
      'category': 'Offers',
      'isUnread': true,
      'icon': Icons.local_offer,
      'iconColor': Colors.orangeAccent,
      'iconBg': Colors.orange.withOpacity(0.2),
    },
    {
      'title': 'Rate Your Last Trip',
      'message': 'How was your transfer from Airport to Lara Beach? Your feedback helps us improve.',
      'time': '3 hours ago',
      'category': 'Bookings',
      'isUnread': false,
      'icon': Icons.star,
      'iconColor': const Color(0xFFF27A22),
      'iconBg': const Color(0xFFF27A22).withOpacity(0.2),
    },
    {
      'title': 'Driver On The Way',
      'message': 'Mehmet is heading to Antalya Airport. He will arrive in approximately 5 minutes. Black Mercedes Vito, plate 07 ANT 456.',
      'time': 'Yesterday',
      'category': 'Bookings',
      'isUnread': false,
      'icon': Icons.directions_car,
      'iconColor': Colors.white70,
      'iconBg': Colors.white10,
    },
    {
      'title': 'AI Concierge Tip',
      'message': 'The weather in Belek will be 28°C and sunny tomorrow. Perfect for visiting Aspendos! Shall I arrange a transfer?',
      'time': 'Yesterday',
      'category': 'System',
      'isUnread': false,
      'icon': Icons.auto_awesome,
      'iconColor': Colors.purpleAccent,
      'iconBg': Colors.purple.withOpacity(0.2),
    },
    {
      'title': 'Payment Successful',
      'message': 'Your payment of €35.00 for the Airport → Belek transfer has been processed successfully.',
      'time': '2 days ago',
      'category': 'System',
      'isUnread': false,
      'icon': Icons.credit_card,
      'iconColor': Colors.blueAccent,
      'iconBg': Colors.blue.withOpacity(0.2),
    },
    {
      'title': 'Gold Member Reward',
      'message': 'Congratulations! You have earned Gold Member status. Enjoy priority booking and exclusive discounts.',
      'time': '3 days ago',
      'category': 'Offers',
      'isUnread': false,
      'icon': Icons.card_giftcard,
      'iconColor': Colors.amber,
      'iconBg': Colors.amber.withOpacity(0.2),
    },
  ];

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filteredList = notifications;
    if (selectedFilter != 'All') {
      filteredList = notifications.where((n) => n['category'] == selectedFilter).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 12, bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(color: const Color(0xFF3B2A2E), borderRadius: BorderRadius.circular(12)),
              alignment: Alignment.center,
              child: const Text('2 new', style: TextStyle(color: Color(0xFFF27A22), fontSize: 10, fontWeight: FontWeight.bold)),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                _buildFilterChip('All'),
                const SizedBox(width: 8),
                _buildFilterChip('Bookings'),
                const SizedBox(width: 8),
                _buildFilterChip('Offers'),
                const SizedBox(width: 8),
                _buildFilterChip('System'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return _buildNotificationCard(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    bool isSelected = selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF27A22) : const Color(0xFF1E2742),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2742),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: item['iconBg'], borderRadius: BorderRadius.circular(10)),
            child: Icon(item['icon'], color: item['iconColor'], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Text(item['message'], style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                const SizedBox(height: 8),
                Text(item['time'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
              ],
            ),
          ),
          if (item['isUnread'])
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFF27A22), shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

class ConfirmBookingScreen extends StatefulWidget {
  final String vehicleName;
  final String vehicleSubtitle;
  final String price;
  final String imagePath;
  final String pickup;
  final String dropoff;
  final String date;
  final String time;
  final String pax;

  const ConfirmBookingScreen({
    super.key,
    required this.vehicleName,
    required this.vehicleSubtitle,
    required this.price,
    required this.imagePath,
    required this.pickup,
    required this.dropoff,
    required this.date,
    required this.time,
    required this.pax,
  });

  @override
  State<ConfirmBookingScreen> createState() => _ConfirmBookingScreenState();
}

class _ConfirmBookingScreenState extends State<ConfirmBookingScreen> {
  int selectedPayment = 0;

  @override
  Widget build(BuildContext context) {
    double transferFee = double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    double serviceFee = 1.25;
    double total = transferFee + serviceFee;

    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Confirm Booking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0, top: 10, bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.lock, color: Colors.greenAccent, size: 16),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E66), Color(0xFF3B2A2E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Image.asset(widget.imagePath, height: 80, fit: BoxFit.contain, errorBuilder: (c, e, s) => const Icon(Icons.directions_car, size: 80, color: Colors.white24)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.vehicleName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          Text(widget.vehicleSubtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                      Text(widget.price, style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Trip Details', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Trip Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E2742), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.flight_takeoff, color: Color(0xFFF27A22), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pick-up', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          Text(widget.pickup, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 9, top: 4, bottom: 4),
                    height: 15,
                    width: 1,
                    color: Colors.white24,
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFF27A22), size: 20),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Drop-off', style: TextStyle(color: Colors.white38, fontSize: 10)),
                          Text(widget.dropoff, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _buildInfoBox(Icons.calendar_today, widget.date)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInfoBox(Icons.access_time, widget.time)),
                      const SizedBox(width: 8),
                      Expanded(child: _buildInfoBox(Icons.person, '${widget.pax} pax')),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Payment Methods Card
            Container(
              decoration: BoxDecoration(color: const Color(0xFF1E2742), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildPaymentOption(0, Icons.credit_card, 'Credit / Debit Card', '**** 4589'),
                  const Divider(color: Colors.white10, height: 1),
                  _buildPaymentOption(1, Icons.paypal, 'PayPal', 'alperen@gmail.com'),
                  const Divider(color: Colors.white10, height: 1),
                  _buildPaymentOption(2, Icons.money, 'Cash on Arrival', 'Pay the driver'),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Price Summary', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Price Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF1E2742), borderRadius: BorderRadius.circular(16)),
              child: Column(
                children: [
                  _buildPriceRow('Transfer Fee', '€${transferFee.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildPriceRow('Service Fee', '€${serviceFee.toStringAsFixed(2)}'),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.0),
                    child: Divider(color: Colors.white10),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('€${total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFFB74D), fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Confirm Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to the Success Screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingSuccessScreen(
                        vehicleName: widget.vehicleName,
                        date: widget.date,
                        time: widget.time,
                        pickup: widget.pickup,
                        dropoff: widget.dropoff,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.shield, color: Colors.white, size: 18),
                label: const Text('Confirm & Pay', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF27A22),
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: const Color(0xFF2C3E66), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFF27A22), size: 14),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(int index, IconData icon, String title, String subtitle) {
    bool isSelected = selectedPayment == index;
    return InkWell(
      onTap: () => setState(() => selectedPayment = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: isSelected ? Border.all(color: const Color(0xFFF27A22), width: 1) : Border.all(color: Colors.transparent),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: Colors.white70, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isSelected ? const Color(0xFFF27A22) : Colors.white38,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
        Text(amount, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}


class BookingSuccessScreen extends StatelessWidget {
  final String vehicleName;
  final String date;
  final String time;
  final String pickup;
  final String dropoff;

  const BookingSuccessScreen({
    super.key,
    required this.vehicleName,
    required this.date,
    required this.time,
    required this.pickup,
    required this.dropoff,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a random-looking Booking ID
    final String bookingId = "#RAY-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}";

    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.green, width: 2),
                ),
                child: const Icon(Icons.check, color: Colors.green, size: 40),
              ),
              const SizedBox(height: 24),
              const Text(
                'Booking Confirmed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Your $vehicleName transfer has been booked successfully. Driver details will be sent to you 1 hour before pickup.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Details Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2742),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Booking ID', bookingId),
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow('Vehicle', vehicleName),
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow('Date & Time', '$date, $time'),
                    const Divider(color: Colors.white10, height: 24),
                    _buildDetailRow('Route', '${pickup.split(' ')[0]} → ${dropoff.split(' ')[0]}'),
                  ],
                ),
              ),
              const Spacer(),

              // Back to Home Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Go back to the very first screen (MainScreen)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainScreen()),
                          (Route<dynamic> route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF27A22),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Back to Home', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 14)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }
}







class ToursScreen extends StatelessWidget {
  const ToursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Day-Trip Tours',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildTourCard(context, 'Aspendos & Perge', 'Explore ancient ruins and amphitheaters.', '€45'),
              _buildTourCard(context, 'Pamukkale Day Trip', 'Thermal pools and Hierapolis tour.', '€65'),
              _buildTourCard(context, 'Olympos Cable Car', 'Panoramic views from Mount Tahtali.', '€55'),
              _buildTourCard(context, 'Kaleiçi Old Town Tour', 'Guided walking tour through historic Antalya.', '€25'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTourCard(BuildContext context, String title, String desc, String price) {
    return Card(
      color: const Color(0xFF1E2742),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.tour, color: Color(0xFFF27A22), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(desc, style: const TextStyle(color: Colors.white54)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(price, style: const TextStyle(color: Color(0xFFF27A22), fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => TourBookingScreen(
                          title: title,
                          desc: desc,
                          basePrice: price,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0xFFF27A22), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Book', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}





class TourBookingScreen extends StatefulWidget {
  final String title;
  final String desc;
  final String basePrice;

  const TourBookingScreen({super.key, required this.title, required this.desc, required this.basePrice});

  @override
  State<TourBookingScreen> createState() => _TourBookingScreenState();
}

class _TourBookingScreenState extends State<TourBookingScreen> {
  DateTime selectedDate = DateTime.now();
  int pax = 1;

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFF27A22),
              onPrimary: Colors.white,
              surface: Color(0xFF2C3E66),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF1E2742),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    double priceVal = double.tryParse(widget.basePrice.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;
    double total = priceVal * pax;

    return Scaffold(
      backgroundColor: const Color(0xFF151B2D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Configure Tour', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.desc, style: const TextStyle(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 30),

                const Text('Select Date', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFF1E2742), borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFFF27A22)),
                        const SizedBox(width: 12),
                        Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: const TextStyle(color: Colors.white, fontSize: 16)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                const Text('Number of Passengers', style: TextStyle(color: Colors.white, fontSize: 16)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF1E2742), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$pax Passenger${pax > 1 ? 's' : ''}', style: const TextStyle(color: Colors.white, fontSize: 16)),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() { if (pax > 1) pax--; }),
                            icon: const Icon(Icons.remove_circle_outline, color: Color(0xFFF27A22)),
                          ),
                          Text('$pax', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(
                            onPressed: () => setState(() => pax++),
                            icon: const Icon(Icons.add_circle_outline, color: Color(0xFFF27A22)),
                          ),
                        ],
                      )
                    ],
                  ),
                ),

                const Spacer(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Price:', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    Text('€${total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFF27A22), fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      String assignedVehicle;
                      String assignedImage;

                      if (pax <= 4) {
                        assignedVehicle = "Mercedes Benz";
                        assignedImage = 'assets/classs.png';
                      } else if (pax <= 9) {
                        assignedVehicle = "Mercedes Vito";
                        assignedImage = 'assets/vito.png';
                      } else {
                        assignedVehicle = "Mercedes Sprinter";
                        assignedImage = 'assets/sprinter7.png';
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConfirmBookingScreen(
                            vehicleName: assignedVehicle,
                            vehicleSubtitle: widget.title,
                            price: '€${total.toStringAsFixed(2)}',
                            imagePath: assignedImage,
                            pickup: 'Your Hotel',
                            dropoff: widget.title,
                            date: "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            time: '09:00',
                            pax: pax.toString(),
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF27A22),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Continue to Payment', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}