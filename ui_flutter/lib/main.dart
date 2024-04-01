import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart';
import 'video_page.dart';
import 'app_state.dart';
import 'firebase_options.dart';
import 'report_page.dart';
import 'Login.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(ChangeNotifierProvider(
    create: (context) => ApplicationState(),
    builder: ((context, child) => const App()),
  ));

}

bool isloggedIn = false;

// Add GoRouter configuration outside the App class
final _router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) {
    // Check if user is logged in
    final loggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.uri.toString() == '/';

    // Redirect to home page if logged in and on login page
    if (loggedIn && loggingIn) return '/myHome_page';
    // Redirect to login page if not logged in and trying to access a restricted page
    if (!loggedIn && !loggingIn) return '/';
    
    // No redirection if none of the above conditions are met
    return null;
  },

  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => LogInPage(),
      routes: [
        GoRoute(
          path: 'sign-in',
          builder: (context, state) {
            return SignInScreen(
              actions: [
                ForgotPasswordAction(((context, email) {
                  final uri = Uri(
                    path: '/sign-in/forgot-password',
                    queryParameters: <String, String?>{
                      'email': email,
                    },
                  );
                  context.push(uri.toString());
                })),
                AuthStateChangeAction(((context, state) {
                  final user = switch (state) {
                    SignedIn state => state.user,
                    UserCreated state => state.credential.user,
                    _ => null
                  };
                  if (user == null) {
                    return;
                  }
                  if (state is UserCreated) {
                    user.updateDisplayName(user.email!.split('@')[0]);
                  }
                  if (!user.emailVerified) {
                    user.sendEmailVerification();
                    const snackBar = SnackBar(
                        content: Text(
                            'Please check your email to verify your email address'));
                    ScaffoldMessenger.of(context).showSnackBar(snackBar);
                  }
                  // context.pushReplacement('/');
                  // context.pushReplacement('/');
                  // context.push('/home_page');
                  context.go('/myHome_page');
                })),
              ],
            );
          },
          routes: [
            GoRoute(
              path: 'forgot-password',
              builder: (context, state) {
                final arguments = state.uri.queryParameters;
                return ForgotPasswordScreen(
                  email: arguments['email'],
                  headerMaxExtent: 200,
                );
              },
            ),
          ],
        ),
        GoRoute(
          path: 'profile',
          builder: (context, state) {
            return ProfileScreen(
              providers: const [],
              actions: [
                SignedOutAction((context) {
                  context.pushReplacement('/');
                }),
              ],
            );
          },
        ),
      ],
    ),
    GoRoute(
      path: '/myHome_page',
      builder: (context, state) => MyHomePage(),
    ),
    GoRoute(
      path:'/report_page',
      builder: (context, state) => ReportPage(),
    ),
    GoRoute(
      path: '/video_page',
      builder: (context, state) => VideoPage(),
    )
  ],
  
);
// end of GoRouter configuration

// Change MaterialApp to MaterialApp.router and add the routerConfig
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    isloggedIn = Provider.of<ApplicationState>(context).loggedIn;
   

    return MaterialApp.router(
      theme: ThemeData(
        buttonTheme: Theme.of(context).buttonTheme.copyWith(
              highlightColor: Colors.deepPurple,
            ),
        primarySwatch: Colors.deepPurple,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      routerConfig: _router,
      // routeInformationParser: _router.routeInformationParser,
      // routerDelegate: _router.routerDelegate,
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  

  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = VideoPage();
        // context.push('/report_page');
        break;
      case 1:
        page = ReportPage();
        // context.push('/login_page');
        break;
      case 2:
        page = LogInPage();
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Scaffold(
          body: SafeArea(
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Container(
                    child: page,
                  )
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(
                icon: Icon(Icons.video_collection),
                label: 'Video'
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.file_copy_sharp),
                label: 'Report',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle),
                label: 'Account',
              ),
              
            ],
            currentIndex: selectedIndex,
            onTap: (value) {
              setState(() {
                selectedIndex = value;
              });
            },
          
          ),
          
        );
      }
    );
  }
}
