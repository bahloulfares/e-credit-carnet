import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

export 'package:flutter_localizations/flutter_localizations.dart';

/// Simple dual-language localizations (FR + AR).
/// Usage: AppLocalizations.of(context).t('key')
/// Or via extension: context.l10n.t('key')
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('fr'));
  }

  bool get isAr => locale.languageCode == 'ar';

  static const delegate = _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    _AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [Locale('fr'), Locale('ar')];

  // ─── All strings ────────────────────────────────────────────────────────────

  static const _fr = <String, String>{
    // General
    'appTitle': 'ProCrédit',
    'error': 'Erreur',
    'cancel': 'Annuler',
    'save': 'Enregistrer',
    'confirm': 'Confirmer',
    'yes': 'Oui',
    'no': 'Non',
    'password': 'Mot de passe *',
    'loading': 'Chargement...',
    'retry': 'Réessayer',
    'success': 'Succès',
    'requiredFields': 'Veuillez remplir tous les champs obligatoires',
    'invalidEmailFormat': 'Format d\'email invalide',
    'clientIdRequired': 'ID client requis',
    'clientIdAndNameRequired': 'ID et nom client requis pour les transactions',

    // Dashboard
    'dashboard': 'Tableau de bord',
    'totalClients': 'Clients',
    'totalDebt': 'Encours total',
    'totalCredit': 'Crédits accordés',
    'totalPayment': 'Paiements reçus',
    'thisMonth': 'Ce mois-ci',
    'transactions': 'Transactions',
    'credits': 'Crédits',
    'payments': 'Paiements',
    'recentTransactions': 'Dernières transactions',
    'syncStatusTitle': 'Statut synchronisation',
    'offlineMode':
        'Mode hors ligne — les modifications seront synchronisees a la prochaine connexion.',
    'syncNow': 'Synchroniser',
    'syncCompleted': 'Synchronisation terminee',
    'autoSyncCompleted': 'Synchronisation automatique effectuee',
    'pinTitle': 'Entrez votre code PIN',
    'pinAuthFailed': 'Echec de verification. Reessayez plus tard.',
    'pinWrong': 'Code PIN incorrect',
    'pinBlocked': 'Trop de tentatives. Attendez',
    'pinSetHint': 'Choisissez un nouveau code PIN a 4 chiffres',
    'pinConfirmHint': 'Confirmez votre code PIN',
    'pinMismatch': 'Les codes PIN ne correspondent pas. Recommencez.',
    'pinSetSuccess': 'Code PIN configure avec succes',
    'pinDisableHint': 'Entrez votre code PIN actuel',
    'pinDisableSuccess': 'Code PIN desactive avec succes',
    'pinDisableFailed': 'Code PIN incorrect',
    'pinChangeSuccess': 'Code PIN modifie avec succes',
    'forgotPin': 'Code PIN oublie ? Se deconnecter',
    'pinManagement': 'Verrouillage de l\'ecran',
    'pinTooltip':
        'Protegez l\'acces a l\'application avec un code PIN a 4 chiffres',
    'enablePin': 'Activer le verrouillage PIN',
    'changePin': 'Changer le code PIN',
    'disablePin': 'Desactiver le verrouillage PIN',
    'useBiometric': 'Utiliser la biometrie',
    'lockNow': 'Verrouiller maintenant',
    'lockNowDone': 'Application verrouillee',
    'lockStatusActive': 'Verrouillage actif',
    'lockStatusInactive': 'Verrouillage inactif',
    'syncFailed': 'Echec synchronisation',
    'autoRetry': 'Auto-retry dans',
    'syncing': 'Synchronisation en cours...',
    'pendingSyncs': 'Elements en attente',
    'localPendingSyncs': 'Elements locaux en attente',
    'lastSync': 'Derniere synchronisation',
    'syncResult': 'Resultat',
    'neverSynced': 'Jamais synchronise',
    'unknownStatus': 'Inconnu',
    'syncStatusError': 'Impossible de charger le statut de synchronisation',
    'apiHealth': 'Sante API',
    'apiHealthTitle': 'Diagnostic API',
    'backendReachable': 'Backend accessible',
    'backendUnreachable': 'Backend inaccessible',
    'healthCheckSuccess': 'Health check reussi',
    'endpointLabel': 'Endpoint',
    'responseStatus': 'Statut reponse',
    'responseTime': 'Horodatage reponse',

    // Clients
    'clients': 'Clients',
    'searchClients': 'Rechercher un client...',
    'noClients': 'Aucun client. Appuyez sur + pour en ajouter un.',
    'noResults': 'Aucun résultat',
    'noPhone': 'Pas de téléphone',
    'debt': 'Dette',
    'endOfClientList': 'Fin de la liste des clients',

    // Client details
    'clientDetails': 'Détails client',
    'financialSummary': 'Résumé financier',
    'phone': 'Téléphone',
    'email': 'Email',
    'address': 'Adresse',
    'shopName': 'Nom de boutique',
    'clientTotalCredit': 'Crédit total',
    'clientTotalPayment': 'Paiement total',
    'currentDebt': 'Dette actuelle',
    'addTransaction': 'Ajouter une transaction',
    'viewAllTransactions': 'Voir toutes les transactions',
    'deactivateClient': 'Désactiver le client ?',
    'reactivateClient': 'Réactiver le client ?',
    'deactivateClientMsg':
        'Le client ne pourra plus être sélectionné pour de nouvelles transactions.\nSes données seront conservées.',
    'reactivateClientMsg':
        'Le client pourra à nouveau effectuer des transactions.',
    'deactivate': 'Désactiver',
    'reactivate': 'Réactiver',
    'clientDeactivated': 'Client désactivé',
    'clientReactivated': 'Client réactivé',
    'inactive': 'Inactif',

    // Add client
    'addClient': 'Ajouter un client',
    'firstName': 'Prénom *',
    'lastName': 'Nom *',
    'firstNameRequired': 'Le prénom est obligatoire',
    'lastNameRequired': 'Le nom est obligatoire',
    'clientSaved': 'Client enregistré avec succès',
    'clientUpdated': 'Client mis a jour avec succes',
    'editClient': 'Modifier client',
    'updateClientError': 'Erreur lors de la mise a jour du client',
    'saveClient': 'Enregistrer le client',
    'sessionExpired': 'Session expirée. Veuillez vous reconnecter.',
    'roleAccessDenied': 'Accès refusé pour ce rôle.',
    'similarClientExists': 'Un client similaire existe déjà.',
    'createClientFailed':
        'Impossible de créer le client pour le moment. Réessayez.',

    // Transactions
    'transactionsOf': 'Transactions',
    'allTypes': 'Tous',
    'creditType': 'Crédits',
    'paymentType': 'Paiements',
    'noTransactionsFilter': 'Aucune transaction pour ce filtre',
    'endOfTransactionList': 'Fin de la liste des transactions',
    'addTransactionFab': 'Ajouter',
    'newTransaction': 'Nouvelle transaction',
    'credit': 'Crédit',
    'payment': 'Paiement',
    'amount': 'Montant (DT)',
    'amountReadOnly': 'Le montant ne peut pas etre modifie',
    'amountInvalid': 'Entrez un montant valide',
    'dueDate': 'Date d\'echeance',
    'noDueDate': 'Aucune date d\'echeance',
    'clearDate': 'Effacer la date',
    'description': 'Description (optionnel)',
    'transactionAdded': 'Transaction ajoutée avec succès',
    'transactionUpdated': 'Transaction mise à jour avec succès',
    'transactionDeleted': 'Transaction supprimée avec succès',
    'transactionError': 'Erreur lors de la création',
    'updateTransactionError': 'Erreur lors de la mise à jour',
    'deleteTransactionError': 'Erreur lors de la suppression',
    'cash': 'Espèces',
    'paymentMethod': 'Méthode de paiement',
    'paymentStatus': 'Statut paiement',
    'allPaymentStatus': 'Tous les statuts',
    'paidStatus': 'Payées',
    'unpaidStatus': 'Non payées',
    'type': 'Type',
    'allMonths': 'Tous les mois',
    'allYears': 'Toutes les années',
    'filterByPeriod': 'Filtrer par période',
    'editTransaction': 'Modifier transaction',
    'deleteTransaction': 'Supprimer transaction',
    'edit': 'Modifier',
    'delete': 'Supprimer',
    'confirmDeleteTransaction':
        'Voulez-vous vraiment supprimer cette transaction ?',

    // Months
    'jan': 'Janvier',
    'feb': 'Février',
    'mar': 'Mars',
    'apr': 'Avril',
    'may': 'Mai',
    'jun': 'Juin',
    'jul': 'Juillet',
    'aug': 'Août',
    'sep': 'Septembre',
    'oct': 'Octobre',
    'nov': 'Novembre',
    'dec': 'Décembre',

    // Drawer
    'gestionEpiciers': 'Gestion Épiciers',
    'profile': 'Profil',
    'settings': 'Parametre',
    'createAccount': 'Creer un compte',
    'registerYourShop': 'Inscrivez votre boutique',
    'register': 'S\'inscrire',
    'alreadyHaveAccountLogin': 'Vous avez deja un compte ? Connexion',
    'userNotConnected': 'Utilisateur non connecte',
    'roleLabel': 'Role',
    'subscriptionLabel': 'Abonnement',
    'saveProfile': 'Enregistrer le profil',
    'profileUpdatedSuccess': 'Profil mis a jour avec succes',
    'forgotPasswordContactAdmin':
        'Contactez votre administrateur pour reinitialiser le mot de passe',
    'refresh': 'Rafraîchir',
    'dataRefreshed': 'Données rafraîchies',
    'logout': 'Déconnexion',
    'logoutConfirm': 'Voulez-vous vraiment vous déconnecter ?',
    'switchLanguage': 'العربية',
    'language': 'Langue',
    'cashOnlyForNow': 'Paiement en espèces uniquement pour le moment',
    'darkThemeTitle': 'Theme sombre',
    'darkThemeSubtitle': 'Activer le mode sombre',
    'biometricSettingHint': 'Autoriser le deverrouillage biometrique',

    // Profile
    'myProfile': 'Mon profil',

    // Admin
    'adminDashboard': 'Tableau de bord admin',
    'adminEpiciers': 'Épiciers',
  };

  static const _ar = <String, String>{
    // General
    'appTitle': 'بروكريدي',
    'error': 'خطأ',
    'cancel': 'إلغاء',
    'save': 'حفظ',
    'confirm': 'تأكيد',
    'yes': 'نعم',
    'no': 'لا',
    'password': 'كلمة المرور *',
    'loading': 'جاري التحميل...',
    'retry': 'إعادة المحاولة',
    'success': 'نجاح',
    'requiredFields': 'يرجى ملء كل الحقول المطلوبة',
    'invalidEmailFormat': 'تنسيق البريد الإلكتروني غير صالح',
    'clientIdRequired': 'مطلوب معرف العميل',
    'clientIdAndNameRequired': 'مطلوب معرف واسم العميل لعرض المعاملات',

    // Dashboard
    'dashboard': 'لوحة التحكم',
    'totalClients': 'العملاء',
    'totalDebt': 'إجمالي الديون',
    'totalCredit': 'الائتمان الممنوح',
    'totalPayment': 'المدفوعات المستلمة',
    'thisMonth': 'هذا الشهر',
    'transactions': 'المعاملات',
    'credits': 'الائتمانات',
    'payments': 'المدفوعات',
    'recentTransactions': 'آخر المعاملات',
    'syncStatusTitle': 'حالة المزامنة',
    'offlineMode': 'وضع غير متصل — سيتم مزامنة التغييرات عند الاتصال التالي.',
    'syncNow': 'مزامنة الان',
    'syncCompleted': 'تمت المزامنة',
    'autoSyncCompleted': 'تمت المزامنة التلقائية',
    'pinTitle': 'أدخل رمز PIN',
    'pinAuthFailed': 'فشل التحقق. حاول لاحقا.',
    'pinWrong': 'رمز PIN غير صحيح',
    'pinBlocked': 'محاولات خاطئة كثيرة. انتظر',
    'pinSetHint': 'اختر رمز PIN من 4 أرقام',
    'pinConfirmHint': 'أكد رمز PIN الخاص بك',
    'pinMismatch': 'رموز PIN غير متطابقة. حاول مجددا.',
    'pinSetSuccess': 'تم تعيين رمز PIN بنجاح',
    'pinDisableHint': 'أدخل رمز PIN الحالي',
    'pinDisableSuccess': 'تم إلغاء تفعيل رمز PIN',
    'pinDisableFailed': 'رمز PIN غير صحيح',
    'pinChangeSuccess': 'تم تغيير رمز PIN بنجاح',
    'forgotPin': 'نسيت رمز PIN؟ تسجيل الخروج',
    'pinManagement': 'قفل الشاشة',
    'pinTooltip': 'احمِ الوصول إلى التطبيق بـ PIN من 4 أرقام',
    'enablePin': 'تفعيل قفل PIN',
    'changePin': 'تغيير رمز PIN',
    'disablePin': 'إلغاء قفل PIN',
    'useBiometric': 'استخدام البصمة',
    'lockNow': 'اقفل الآن',
    'lockNowDone': 'تم قفل التطبيق',
    'lockStatusActive': 'القفل مفعل',
    'lockStatusInactive': 'القفل غير مفعل',
    'syncFailed': 'فشلت المزامنة',
    'autoRetry': 'إعادة محاولة تلقائية في',
    'syncing': 'جاري المزامنة...',
    'pendingSyncs': 'العناصر المعلقة',
    'localPendingSyncs': 'العناصر المحلية المعلقة',
    'lastSync': 'اخر مزامنة',
    'syncResult': 'النتيجة',
    'neverSynced': 'لم تتم مزامنة من قبل',
    'unknownStatus': 'غير معروف',
    'syncStatusError': 'تعذر تحميل حالة المزامنة',
    'apiHealth': 'صحة API',
    'apiHealthTitle': 'تشخيص API',
    'backendReachable': 'الخلفية متاحة',
    'backendUnreachable': 'الخلفية غير متاحة',
    'healthCheckSuccess': 'فحص الصحة ناجح',
    'endpointLabel': 'نقطة النهاية',
    'responseStatus': 'حالة الاستجابة',
    'responseTime': 'وقت الاستجابة',

    // Clients
    'clients': 'العملاء',
    'searchClients': 'البحث عن عميل...',
    'noClients': 'لا يوجد عملاء. اضغط + للإضافة.',
    'noResults': 'لا توجد نتائج',
    'noPhone': 'لا يوجد رقم هاتف',
    'debt': 'الدين',
    'endOfClientList': 'نهاية قائمة العملاء',

    // Client details
    'clientDetails': 'تفاصيل العميل',
    'financialSummary': 'الملخص المالي',
    'phone': 'الهاتف',
    'email': 'البريد الإلكتروني',
    'address': 'العنوان',
    'shopName': 'اسم المتجر',
    'clientTotalCredit': 'إجمالي الائتمان',
    'clientTotalPayment': 'إجمالي المدفوعات',
    'currentDebt': 'الدين الحالي',
    'addTransaction': 'إضافة معاملة',
    'viewAllTransactions': 'عرض كل المعاملات',
    'deactivateClient': 'تعطيل العميل؟',
    'reactivateClient': 'إعادة تفعيل العميل؟',
    'deactivateClientMsg':
        'لن يتمكن العميل من إجراء معاملات جديدة.\nسيتم الاحتفاظ ببياناته.',
    'reactivateClientMsg': 'سيتمكن العميل من إجراء المعاملات مرة أخرى.',
    'deactivate': 'تعطيل',
    'reactivate': 'إعادة تفعيل',
    'clientDeactivated': 'تم تعطيل العميل',
    'clientReactivated': 'تم إعادة تفعيل العميل',
    'inactive': 'غير نشط',

    // Add client
    'addClient': 'إضافة عميل',
    'firstName': 'الاسم الأول *',
    'lastName': 'اسم العائلة *',
    'firstNameRequired': 'الاسم الأول مطلوب',
    'lastNameRequired': 'اسم العائلة مطلوب',
    'clientSaved': 'تم حفظ العميل بنجاح',
    'clientUpdated': 'تم تحديث العميل بنجاح',
    'editClient': 'تعديل العميل',
    'updateClientError': 'خطأ أثناء تحديث العميل',
    'saveClient': 'حفظ العميل',
    'sessionExpired': 'انتهت الجلسة. يرجى تسجيل الدخول مجدداً.',
    'roleAccessDenied': 'غير مسموح لهذا الدور.',
    'similarClientExists': 'يوجد عميل مشابه بالفعل.',
    'createClientFailed': 'تعذر إنشاء العميل حالياً. حاول مرة أخرى.',

    // Transactions
    'transactionsOf': 'معاملات',
    'allTypes': 'الكل',
    'creditType': 'ائتمانات',
    'paymentType': 'مدفوعات',
    'noTransactionsFilter': 'لا توجد معاملات لهذا التصفية',
    'endOfTransactionList': 'نهاية قائمة المعاملات',
    'addTransactionFab': 'إضافة',
    'newTransaction': 'معاملة جديدة',
    'credit': 'ائتمان',
    'payment': 'دفع',
    'amount': 'المبلغ (د.ت)',
    'amountReadOnly': 'لا يمكن تعديل المبلغ',
    'amountInvalid': 'أدخل مبلغاً صحيحاً',
    'dueDate': 'تاريخ الاستحقاق',
    'noDueDate': 'لا يوجد تاريخ استحقاق',
    'clearDate': 'مسح التاريخ',
    'description': 'الوصف (اختياري)',
    'transactionAdded': 'تمت إضافة المعاملة بنجاح',
    'transactionUpdated': 'تم تحديث المعاملة بنجاح',
    'transactionDeleted': 'تم حذف المعاملة بنجاح',
    'transactionError': 'خطأ في إنشاء المعاملة',
    'updateTransactionError': 'خطأ أثناء تحديث المعاملة',
    'deleteTransactionError': 'خطأ أثناء حذف المعاملة',
    'cash': 'نقداً',
    'paymentMethod': 'طريقة الدفع',
    'paymentStatus': 'حالة الدفع',
    'allPaymentStatus': 'كل الحالات',
    'paidStatus': 'مدفوعة',
    'unpaidStatus': 'غير مدفوعة',
    'type': 'النوع',
    'allMonths': 'كل الأشهر',
    'allYears': 'كل السنوات',
    'filterByPeriod': 'تصفية حسب الفترة',
    'editTransaction': 'تعديل المعاملة',
    'deleteTransaction': 'حذف المعاملة',
    'edit': 'تعديل',
    'delete': 'حذف',
    'confirmDeleteTransaction': 'هل تريد حذف هذه المعاملة فعلاً؟',

    // Months
    'jan': 'جانفي',
    'feb': 'فيفري',
    'mar': 'مارس',
    'apr': 'أفريل',
    'may': 'ماي',
    'jun': 'جوان',
    'jul': 'جويليه',
    'aug': 'أوت',
    'sep': 'سبتمبر',
    'oct': 'أكتوبر',
    'nov': 'نوفمبر',
    'dec': 'ديسمبر',

    // Drawer
    'gestionEpiciers': 'إدارة البقالين',
    'profile': 'الملف الشخصي',
    'settings': 'الإعدادات',
    'createAccount': 'إنشاء حساب',
    'registerYourShop': 'سجّل متجرك',
    'register': 'تسجيل',
    'alreadyHaveAccountLogin': 'لديك حساب بالفعل؟ تسجيل الدخول',
    'userNotConnected': 'المستخدم غير متصل',
    'roleLabel': 'الدور',
    'subscriptionLabel': 'الاشتراك',
    'saveProfile': 'حفظ الملف الشخصي',
    'profileUpdatedSuccess': 'تم تحديث الملف الشخصي بنجاح',
    'forgotPasswordContactAdmin':
        'يرجى التواصل مع المسؤول لإعادة تعيين كلمة المرور',
    'refresh': 'تحديث',
    'dataRefreshed': 'تم تحديث البيانات',
    'logout': 'تسجيل الخروج',
    'logoutConfirm': 'هل تريد تسجيل الخروج؟',
    'switchLanguage': 'Français',
    'language': 'اللغة',
    'cashOnlyForNow': 'الدفع نقداً فقط في الوقت الحالي',
    'darkThemeTitle': 'الوضع الداكن',
    'darkThemeSubtitle': 'تفعيل الوضع الداكن',
    'biometricSettingHint': 'السماح بفتح القفل بالبصمة',

    // Profile
    'myProfile': 'ملفي الشخصي',

    // Admin
    'adminDashboard': 'لوحة تحكم المسؤول',
    'adminEpiciers': 'البقالون',
  };

  String t(String key) {
    final map = isAr ? _ar : _fr;
    return map[key] ?? key;
  }

  String monthName(int month) {
    const keys = [
      'jan',
      'feb',
      'mar',
      'apr',
      'may',
      'jun',
      'jul',
      'aug',
      'sep',
      'oct',
      'nov',
      'dec',
    ];
    return t(keys[month - 1]);
  }
}

// ─── Delegate ───────────────────────────────────────────────────────────────

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['fr', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// ─── Extension ──────────────────────────────────────────────────────────────

extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
