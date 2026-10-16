import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:cooli/config/app_config.dart';
import 'package:cooli/l10n/app_localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:provider/provider.dart';

import 'providers/language_provider.dart';
import 'providers/theme_provider.dart';
import 'package:cooli/features/activity/view_model/activity_view_model.dart';
import 'package:cooli/features/address/view_model/address_view_model.dart';
import 'package:cooli/features/auth/view_model/auth_view_model.dart';
import 'package:cooli/features/dashboard/view_model/dashboard_view_model.dart';
import 'package:cooli/features/ecommerce/view_model/ecommerce_view_model.dart';
import 'package:cooli/features/onboarding/view_model/onboarding_view_model.dart';
import 'package:cooli/features/porter/view_model/porter_view_model.dart';
import 'package:cooli/features/profile/view_model/profile_view_model.dart';
import 'package:cooli/features/ride/view_model/ride_view_model.dart';
import 'package:cooli/features/services/view_model/services_view_model.dart';
import 'package:cooli/features/splash/view_model/splash_view_model.dart';
import 'package:cooli/features/wallet/view_model/wallet_view_model.dart';
import 'utils/localization.dart';
import 'utils/routes.dart';
import 'utils/themes.dart';

import 'package:cooli/services/session_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SessionManager().init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown],
    );
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => ThemeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => LanguageProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => AuthViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => RideViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => EcommerceViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => ServicesViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => ProfileViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => PorterViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => DashboardViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => OnboardingViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => ActivityViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => AddressViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => WalletViewModel(),
        ),
        ChangeNotifierProvider(
          create: (context) => SplashViewModel(),
        ),
      ],
      builder: (context, child) => ScreenUtilInit(
        designSize: Size(
          AppConfig.designWidth.toDouble(),
          AppConfig.designHeight.toDouble(),
        ),
        builder: (context, child) => AdaptiveTheme(
          initial: AdaptiveThemeMode.light,
          light: appLightTheme,
          dark: appDarkTheme,
          builder: (theme, darkTheme) {
            return MaterialApp(
              navigatorKey: AppConfig.navKey,
              title: AppConfig.appName,
              themeMode: context.watch<ThemeProvider>().themeMode,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [
                Locale('en', ''),
                Locale('ja', ''),
              ],
              theme: themedForLocale(
                theme,
                context.watch<LanguageProvider>().locale,
              ),
              darkTheme: themedForLocale(
                darkTheme,
                context.watch<LanguageProvider>().locale,
              ),
              locale: context.watch<LanguageProvider>().locale,
              initialRoute: '/',
              onGenerateRoute: onAppGenerateRoute(),
              routes: appRoutes(),
              builder: (context, child) {
                LanguageProvider.initContext(context);
                Localization.init(context);

                // if (kDebugMode) {
                //   StackTrace.current.toString().log('', true);
                //   child = AppStackInterceptorBuilder(child: child!);
                // }
                return child!;
              },
            );
          },
        ),
      ),
    );
  }
}
