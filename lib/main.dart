// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Little UX improvements are going to be made when noticed. The bottom navigation bar index can be updated according to the current page's content. There are no problems with functionality at all. Can be launched after publishing procedures. Login page sometimes don't allow correct security code. Login button should set username and password.



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    builder: (context, _) {
      final themeProvider = Provider.of<ThemeProvider>(context);
      return MaterialApp(
        title: "Yıldız OBS Mobil",
        themeMode: themeProvider.themeMode,
        theme: MyThemes.lightTheme,
        darkTheme: MyThemes.darkTheme,
        home: const LoginPage(),
        debugShowCheckedModeBanner: false,
      );
    },
  ));
}

class MyThemes {
  static final darkTheme = ThemeData(
    textTheme: GoogleFonts.ubuntuTextTheme().apply(bodyColor: Colors.white),
    scaffoldBackgroundColor: Colors.grey.shade900,
    colorScheme: const ColorScheme.dark(
      primary: Color.fromARGB(255, 37, 150, 190),
      secondary: Color(0xffa19065),
    ),
  );
  static final lightTheme = ThemeData(
    textTheme: GoogleFonts.ubuntuTextTheme(),
    scaffoldBackgroundColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color.fromARGB(255, 37, 150, 190),
      secondary: Color(0xffa19065),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  ThemeMode themeMode = ThemeMode.dark;
  bool get isDarkMode => themeMode == ThemeMode.dark;

  ThemeProvider() {
    _getThemePreference();
  }

  Future<void> _getThemePreference() async {
    final themePreference = await UserSecureStorage.getTheme();
    themeMode = themePreference == "false" ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }

  void toggleTheme(bool isOn) {
    themeMode = isOn ? ThemeMode.dark : ThemeMode.light;
    _saveThemePreference(isOn);
    notifyListeners();
  }

  Future<void> _saveThemePreference(bool isOn) async {
    await UserSecureStorage.setTheme(isOn.toString());
  }
}

class ChangeThemeButtonWidget extends StatelessWidget {
  const ChangeThemeButtonWidget({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Switch.adaptive(
        activeThumbImage: const AssetImage("assets/images/moonicon.png"),
        inactiveThumbImage: const AssetImage("assets/images/sunicon.png"),
        activeColor: Colors.grey.shade700,
        value: themeProvider.isDarkMode,
        onChanged: (value) async {
          final provider = Provider.of<ThemeProvider>(context, listen: false);
          provider.toggleTheme(value);
        });
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

String obsLink = "https://obs.yildiz.edu.tr/oibs/ogrenci/login.aspx";

class _LoginPageState extends State<LoginPage> {
  late InAppWebViewController edevletcontroller;
  String edevletlink =
      "giris.turkiye.gov.tr/Giris/gir?oauthClientId=640cbd04-b79a-4457-8acf-323ac1d4075b&continue=https%3A%2F%2Fgiris.turkiye.gov.tr%2FOAuth2AuthorizationServer%2FAuthorizationController%3Fresponse_type%3Dcode%26client_id%3D640cbd04-b79a-4457-8acf-323ac1d4075b%26state%3DOgrenci%26scope%3DKimlik-Dogrula%253BAd-Soyad%26redirect_uri%3Dhttps%253A%252F%252Fobs.yildiz.edu.tr%252Frouter.aspx";
  late InAppWebViewController webViewController;
  final TextEditingController secCodeController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController TCKNController = TextEditingController();
  final TextEditingController eDevletPasswordController = TextEditingController();
  late FocusNode secFocusNode;
  late FocusNode usernameFocusNode;
  late FocusNode passwordFocusNode;
  late FocusNode eDevletPasswordFocusNode;
  late String secCode;
  late int webviewwidth;
  bool _obscureText = true;
  bool _obscureTCKN = true;
  bool _infoOffstage = true;
  bool _offstage = true;
  bool secCodeOffstage = true;
  int obsLoadCounter = 0;

  void logOut() async {
    await webViewController.evaluateJavascript(
        source: "__doPostBack('btnRefresh',''); __doPostBack('btnLogout','');");
  }

  void login() async {
    await UserSecureStorage.setUsername(usernameController.text);
    await UserSecureStorage.setPassword(passwordController.text);
    await webViewController.evaluateJavascript(
        source:
        "document.getElementById('txtParamT01').value = '${usernameController.text}';");
    await webViewController.evaluateJavascript(
        source:
        "document.getElementById('txtParamT02').value = '${passwordController.text}';");
    await webViewController.evaluateJavascript(
        source:
        "document.getElementById('txtSecCode').value = '${secCodeController.text}';");
    await webViewController.evaluateJavascript(
        source: "document.getElementById('btnLogin').click();");
  }

  Future init() async {
    final String name = await UserSecureStorage.getUsername();
    final String password = await UserSecureStorage.getPassword();
    final String TCKN = await UserSecureStorage.getTCKN();
    final String eDevletPassword =
    await UserSecureStorage.getEdevletPassword();
    setState(() {
      usernameController.text = name;
      passwordController.text = password;
      TCKNController.text = TCKN;
      eDevletPasswordController.text = eDevletPassword;
    });
    setFocus();
    login();
  }

  @override
  void initState() {
    super.initState();
    secFocusNode = FocusNode();
    usernameFocusNode = FocusNode();
    passwordFocusNode = FocusNode();
    eDevletPasswordFocusNode = FocusNode();
    init();
    secCodeController.text = '';
  }



  void setFocus() {
    if (usernameController.text == '') {
      FocusScope.of(context).requestFocus(usernameFocusNode);
    } else if (passwordController.text == '') {
      FocusScope.of(context).requestFocus(passwordFocusNode);
    } else {
      FocusScope.of(context).requestFocus(secFocusNode);
    }
  }

  void adjustForm() async {
    await webViewController.evaluateJavascript(
        source:
        "setInterval(function() {window.location.reload();}, 300000); var imgCaptchaImg = document.getElementById('imgCaptchaImg'); document.body.appendChild(imgCaptchaImg); imgCaptchaImg.style.width = 'auto';imgCaptchaImg.style.height = 'auto';document.getElementById('form1').style.display = 'none';document.getElementById('imgCaptchaImg').onclick = '';");
  }

  void goToHomePage(String compurl) {
    Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => HomePage(redirecturl: compurl)));
  }

  void handleError(String error, FocusNode node) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    FocusScope.of(context).requestFocus(node);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height,
                width: MediaQuery.of(context).size.width,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height* 2/11 ,
                      child: Image.asset("assets/images/ytu_logo.png"),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(0, 10, 0, 0),
                      child: Text(
                        "YTÜ Öğrenci Bilgi Sistemi",
                        style: TextStyle(fontSize: 22),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
                      child: TextField(
                        focusNode: usernameFocusNode,
                        onChanged: (username) {
                          setState(() {
                            UserSecureStorage.setUsername(username);
                          });
                        },
                        onSubmitted: (username) {
                          setState(()  {
                            UserSecureStorage.setUsername(username);
                          });
                          FocusScope.of(context)
                              .requestFocus(passwordFocusNode);
                        },
                        controller: usernameController,
                        decoration: InputDecoration(
                          focusColor: const Color.fromARGB(255, 28, 39, 86),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                          labelText: "Kullanıcı Adı",
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
                      child: TextField(
                        controller: passwordController,
                        focusNode: passwordFocusNode,
                        onChanged: (password) {
                          setState(() {
                            UserSecureStorage.setPassword(password);
                          });
                        },
                        onSubmitted: (password) {
                          setState(() {
                            UserSecureStorage.setPassword(password);
                          });
                          FocusScope.of(context).requestFocus(secFocusNode);
                        },
                        obscureText: _obscureText,
                        decoration: InputDecoration(
                          focusColor: const Color.fromARGB(255, 28, 39, 86),
                          suffixIcon: IconButton(
                            icon: AnimatedCrossFade(
                              firstChild: const Icon(Icons.visibility_off),
                              secondChild: const Icon(Icons.visibility),
                              crossFadeState: _obscureText
                                  ? CrossFadeState.showFirst
                                  : CrossFadeState.showSecond,
                              duration: const Duration(milliseconds: 250),
                            ),
                            color: Colors.grey,
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                          labelText: "Şifre",
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(15, 20, 15, 10),
                      child: TextFormField(
                        focusNode: secFocusNode,
                        controller: secCodeController,
                        textInputAction: TextInputAction.done,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          focusColor: const Color.fromARGB(255, 28, 39, 86),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setState(() {
                                logOut();
                              });
                            },
                            icon: const Icon(Icons.loop),
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20)),
                          labelText: "Güvenlik Kodu",
                          icon: SizedBox(
                            width: 177,
                            height: 40,
                            child: Stack(
                                alignment: AlignmentDirectional.center,
                                children: [
                                  Offstage(
                                    offstage: secCodeOffstage,
                                    child: InAppWebView(
                                      initialUrlRequest:
                                      URLRequest(url: Uri.parse(obsLink)),
                                      onWebViewCreated:
                                          (InAppWebViewController controller) {
                                        webViewController = controller;
                                      },
                                      onLoadStart:
                                          (InAppWebViewController controller,
                                          Uri? url) {
                                        obsLoadCounter++;
                                        setState(() {
                                          secCodeOffstage = true;
                                        });
                                      },
                                      onLoadStop:
                                          (InAppWebViewController controller,
                                          Uri? url) async {
                                        if (url.toString() != obsLink) {
                                          goToHomePage(url.toString());
                                        } else {
                                          if (obsLoadCounter == 1) {
                                            controller.reload();
                                          }
                                          String sonuc = await controller
                                              .evaluateJavascript(
                                              source:
                                              "document.getElementById('lblSonuclar').innerHTML;")
                                          as String;
                                          if (sonuc ==
                                              'UYARI!! Aynı tarayıcıdan birden fazla giriş yapılamaz. Lütfen tüm açık tarayıcıları kapatın ve tarayıcınızı yeniden başlatın.') {
                                            controller.evaluateJavascript(
                                                source:
                                                "__doPostBack('btnRefresh','');");
                                          } else if (sonuc ==
                                              'Güvenlik kodu hatalı girildi !') {
                                            handleError(
                                                "Güvenlik Kodu hatalı girildi",
                                                secFocusNode);
                                          } else if (sonuc ==
                                              "HATA:D21032301:Kullanıcı adı veya şifresi geçersiz.") {
                                            handleError(
                                                "Kullanıcı Adı veya Şifre hatalı",
                                                passwordFocusNode);
                                          }
                                          adjustForm();
                                          setState(() {
                                            secCodeOffstage = false;
                                          });
                                          secCodeController.clear();
                                        }
                                      },
                                    ),
                                  ),
                                  secCodeOffstage
                                      ? const CircularProgressIndicator()
                                      : Container()
                                ]),
                          ),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Stack(children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:const Color.fromARGB(255, 208, 1, 27),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10))),
                            onPressed: () {
                              setState(() {
                                _offstage = !_offstage;
                              });
                            },
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Image.asset(
                                      "assets/images/edevletgiris.png",
                                      height: 36,
                                      width: 36,
                                    ),
                                    const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text("e-Devlet ile Giriş Yap")),
                                    Container(
                                        width: 0.5,
                                        height: 30,
                                        color: Colors.white.withOpacity(1)),
                                    const SizedBox(width: 10)
                                  ]),
                            ),
                          ),
                          Positioned(
                              right: -10,
                              child: IconButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setStatee) =>
                                          AlertDialog(
                                            title: const Text(
                                              "e-Devlet Giriş Bilgilerini Düzenle",
                                              textAlign: TextAlign.center,
                                            ),
                                            content: SizedBox(
                                              height: 195,
                                              child: Column(
                                                children: [
                                                  Padding(
                                                    padding:
                                                    const EdgeInsets.fromLTRB(
                                                        0, 0, 0, 10),
                                                    child: TextField(
                                                      autofocus: true,
                                                      obscureText: _obscureTCKN,
                                                      keyboardType: TextInputType.number,
                                                      controller: TCKNController,
                                                      onSubmitted: (TCKN) {
                                                        setState(() {
                                                          UserSecureStorage.setTCKN(
                                                              TCKN);
                                                          FocusScope.of(context)
                                                              .requestFocus(
                                                              eDevletPasswordFocusNode);
                                                        });
                                                      },
                                                      textInputAction:
                                                      TextInputAction.next,
                                                      decoration: InputDecoration(
                                                        focusColor:
                                                        const Color.fromARGB(
                                                            255, 28, 39, 86),
                                                        suffixIcon: IconButton(
                                                          icon: AnimatedCrossFade(
                                                            firstChild: const Icon(
                                                                Icons
                                                                    .visibility_off),
                                                            secondChild: const Icon(
                                                                Icons.visibility),
                                                            crossFadeState:
                                                            _obscureTCKN
                                                                ? CrossFadeState
                                                                .showFirst
                                                                : CrossFadeState
                                                                .showSecond,
                                                            duration:
                                                            const Duration(
                                                                milliseconds:
                                                                250),
                                                          ),
                                                          color: Colors.grey,
                                                          onPressed: () {
                                                            setStatee(() {
                                                              _obscureTCKN =
                                                              !_obscureTCKN;
                                                            });
                                                          },
                                                        ),
                                                        border: OutlineInputBorder(
                                                            borderRadius:
                                                            BorderRadius
                                                                .circular(20)),
                                                        labelText:
                                                        "TC Kimlik Numarası",
                                                      ),
                                                    ),
                                                  ),
                                                  TextField(
                                                    controller:
                                                    eDevletPasswordController,
                                                    onSubmitted: (password) {
                                                      UserSecureStorage
                                                          .setEdevletPassword(
                                                          password);
                                                    },
                                                    focusNode:
                                                    eDevletPasswordFocusNode,
                                                    obscureText: true,
                                                    decoration: InputDecoration(
                                                      focusColor:
                                                      const Color.fromARGB(
                                                          255, 28, 39, 86),
                                                      border: OutlineInputBorder(
                                                          borderRadius:
                                                          BorderRadius.circular(
                                                              20)),
                                                      labelText: "e-Devlet Şifresi",
                                                    ),
                                                  ),
                                                  const Padding(
                                                    padding:
                                                    EdgeInsets.only(top: 20),
                                                    child: Text(
                                                      "e-Devlet ile girişlerinizde TCKN ve e-Devlet şifrenizin otomatik doldurulması için bu bölümü doldurabilirsiniz.",
                                                      style:
                                                      TextStyle(fontSize: 14),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            actions: [
                                              Row(
                                                mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                                children: [
                                                  TextButton(
                                                    onPressed: () async {
                                                      UserSecureStorage.setTCKN('');
                                                      UserSecureStorage
                                                          .setEdevletPassword('');
                                                      setState(() {
                                                        TCKNController.text = '';
                                                        eDevletPasswordController
                                                            .text = '';
                                                      });
                                                      Navigator.of(context).pop();
                                                      await edevletcontroller
                                                          .evaluateJavascript(
                                                          source:
                                                          "document.getElementById('tridField').value = ''; document.getElementById('egpField').value = '';");
                                                    },
                                                    child: const Text(
                                                      "Bilgileri Sil",
                                                      style: TextStyle(
                                                          color: Colors.red,
                                                          decoration: TextDecoration
                                                              .underline),
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child: const Text(
                                                          "İptal",
                                                          style: TextStyle(
                                                              color: Colors.red),
                                                        ),
                                                      ),
                                                      TextButton(
                                                        onPressed: () async {
                                                          UserSecureStorage.setTCKN(
                                                              TCKNController.text);
                                                          UserSecureStorage
                                                              .setEdevletPassword(
                                                              eDevletPasswordController
                                                                  .text);
                                                          Navigator.of(context)
                                                              .pop();
                                                          await edevletcontroller
                                                              .evaluateJavascript(
                                                              source:
                                                              "document.getElementById('tridField').value = '${TCKNController.text}'; document.getElementById('egpField').value = '${eDevletPasswordController.text}';");
                                                        },
                                                        child: const Text("Kaydet"),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.settings,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ))
                        ]),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffa19065),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          onPressed: () async {
                            obsLoadCounter = 0;
                            login();
                          },
                          child: const Text("Giriş Yap", style: TextStyle(color: Colors.white),),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: ChangeThemeButtonWidget(),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  verticalDirection: VerticalDirection.down,
                  children: [
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _infoOffstage = !_infoOffstage;
                        });
                        Future.delayed(const Duration(seconds: 10), () {
                          setState(() {
                            _infoOffstage = true;
                          });
                        });
                      },
                      icon: const Icon(Icons.info_outline_rounded),
                    ),
                    AnimatedOpacity(
                        opacity: _infoOffstage ? 0 : 1,
                        duration: const Duration(milliseconds: 200),
                        child: Container(
                            width: MediaQuery.of(context).size.width * 3 / 4,
                            decoration: BoxDecoration(
                              color: Colors.green[800]?.withOpacity(0.9),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(15),
                                bottomLeft: Radius.circular(15),
                                bottomRight: Radius.circular(15),
                              ),
                            ),
                            padding: const EdgeInsets.all(8.0),
                            child: const Text(
                              "Verileriniz bizimle güvende.\nCihazınızda şifreli olarak saklanırlar ve hiçbir zaman üçüncü taraflarla paylaşılmazlar.",
                              softWrap: true,
                              style:
                              TextStyle(fontSize: 11, color: Colors.white),
                            ))),
                  ],
                ),
              ),
              AnimatedOpacity(
                opacity: _offstage ? 0 : 1,
                duration: const Duration(milliseconds: 300),
                child: Offstage(
                  offstage: _offstage,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _offstage = !_offstage;
                      });
                    },
                    child: Container(
                      color: Colors.black.withOpacity(0.5),
                      child: Center(
                        child: SizedBox(
                          height: MediaQuery.of(context).size.width,
                          child: InAppWebView(
                            initialUrlRequest:
                            URLRequest(url: Uri.parse(obsLink)),
                            onWebViewCreated:
                                (InAppWebViewController controller) {
                              edevletcontroller = controller;
                            },
                            onLoadStart: (InAppWebViewController controller,
                                Uri? url) {},
                            onLoadStop: (InAppWebViewController controller,
                                Uri? url) async {
                              controller.evaluateJavascript(
                                  source:
                                  "__doPostBack('btnEdevletLogin','');");
                              Future.delayed(const Duration(seconds: 1),
                                      () async {
                                    await controller.evaluateJavascript(
                                        source:
                                        "document.getElementById('smartbanner').style.display = 'none'; document.querySelector('#loginForm > div.formSubmitRow > input.backButton').style.display = 'none'; document.getElementById('pageContent').scrollIntoView(); document.querySelectorAll('a').forEach(function(link) {link.addEventListener('click', function(event) {event.preventDefault();});});");
                                    String tckn =
                                    await UserSecureStorage.getTCKN();
                                    String eDevletPassword = await UserSecureStorage
                                        .getEdevletPassword();
                                    if (tckn.isNotEmpty &&
                                        eDevletPassword.isNotEmpty) {
                                      await controller.evaluateJavascript(
                                          source:
                                          "document.getElementById('tridField').value = '$tckn'; document.getElementById('egpField').value = '$eDevletPassword';");
                                    }
                                  });
                              if (await controller.canGoBack() &&
                                  url.toString() != edevletlink) {
                                goToHomePage(url.toString());
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserSecureStorage {
  static const _keyTheme = 'dark';
  static const _keyEdevletTCKN = 'TCKN';
  static const _keyEdevletPassword = 'edevletPassword';
  static const _keyUsername = 'username';
  static const _keyPassword = 'password';

  static Future<void> setTheme(String isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTheme, isDark);
  }

  static Future<void> setTCKN(String TCKN) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEdevletTCKN, TCKN);
  }

  static Future<void> setEdevletPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyEdevletPassword, password);
  }

  static Future<void> setPassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPassword, password);
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
  }

  static Future<String> getTCKN() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEdevletTCKN) ?? '';
  }

  static Future<String> getEdevletPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyEdevletPassword) ?? '';
  }

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTheme) ?? '';
  }

  static Future<String> getPassword() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPassword) ?? '';
  }

  static Future<String> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUsername) ?? '';
  }
}