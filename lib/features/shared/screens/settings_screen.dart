import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/providers/app_auth_provider.dart';
import '../../../core/routes/app_router.dart';
import '../../../core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _appVersion = '1.0.0';
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _darkMode = false;
  String _language = 'fr';

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  Future<void> _loadAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = '${packageInfo.version} (${packageInfo.buildNumber})';
      });
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
      ),
      body: ListView(
        children: [
          // Account Section
          _buildSectionHeader('Compte'),
          _buildListTile(
            icon: Icons.person_outline,
            title: 'Modifier le profil',
            subtitle: 'Photo, nom, description',
            onTap: () => Navigator.pushNamed(context, AppRouter.editProfile),
          ),
          _buildListTile(
            icon: Icons.security,
            title: 'Sécurité',
            subtitle: 'Mot de passe, authentification',
            onTap: () => _showSecuritySettings(),
          ),
          _buildListTile(
            icon: Icons.verified_user_outlined,
            title: 'Vérification',
            subtitle: 'Documents et certifications',
            onTap: () => _showVerificationInfo(),
          ),

          const Divider(height: 32),

          // Notifications Section
          _buildSectionHeader('Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Notifications push'),
            subtitle: const Text('Recevoir des notifications sur l\'appareil'),
            value: _notificationsEnabled,
            onChanged: (value) => setState(() => _notificationsEnabled = value),
            activeColor: AppTheme.primaryColor,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.email_outlined),
            title: const Text('Notifications email'),
            subtitle: const Text('Recevoir des emails de rappel'),
            value: _emailNotifications,
            onChanged: (value) => setState(() => _emailNotifications = value),
            activeColor: AppTheme.primaryColor,
          ),
          _buildListTile(
            icon: Icons.tune,
            title: 'Préférences de notification',
            subtitle: 'Personnaliser les types de notification',
            onTap: () => Navigator.pushNamed(context, AppRouter.notifications),
          ),

          const Divider(height: 32),

          // Appearance Section
          _buildSectionHeader('Apparence'),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined),
            title: const Text('Mode sombre'),
            subtitle: const Text('Utiliser le thème sombre'),
            value: _darkMode,
            onChanged: (value) {
              setState(() => _darkMode = value);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fonctionnalité à venir')),
              );
            },
            activeColor: AppTheme.primaryColor,
          ),
          _buildListTile(
            icon: Icons.language,
            title: 'Langue',
            subtitle: _getLanguageName(_language),
            onTap: () => _showLanguageSelector(),
          ),

          const Divider(height: 32),

          // Payment Section
          _buildSectionHeader('Paiement'),
          _buildListTile(
            icon: Icons.credit_card,
            title: 'Méthodes de paiement',
            subtitle: 'Gérer vos cartes bancaires',
            onTap: () => _showPaymentMethods(),
          ),
          _buildListTile(
            icon: Icons.receipt_long,
            title: 'Historique des paiements',
            subtitle: 'Voir vos transactions',
            onTap: () => _showPaymentHistory(),
          ),
          _buildListTile(
            icon: Icons.account_balance,
            title: 'Compte bancaire',
            subtitle: 'Pour recevoir vos paiements',
            onTap: () => _showBankAccount(),
          ),

          const Divider(height: 32),

          // Support Section
          _buildSectionHeader('Support'),
          _buildListTile(
            icon: Icons.help_outline,
            title: 'Centre d\'aide',
            subtitle: 'FAQ et guides',
            onTap: () => _openHelpCenter(),
          ),
          _buildListTile(
            icon: Icons.chat_bubble_outline,
            title: 'Contacter le support',
            subtitle: 'Nous sommes là pour vous aider',
            onTap: () => _contactSupport(),
          ),
          _buildListTile(
            icon: Icons.bug_report_outlined,
            title: 'Signaler un problème',
            subtitle: 'Aidez-nous à améliorer l\'application',
            onTap: () => _reportBug(),
          ),

          const Divider(height: 32),

          // Legal Section
          _buildSectionHeader('Légal'),
          _buildListTile(
            icon: Icons.description_outlined,
            title: 'Conditions d\'utilisation',
            onTap: () => _openTerms(),
          ),
          _buildListTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Politique de confidentialité',
            onTap: () => _openPrivacy(),
          ),
          _buildListTile(
            icon: Icons.gavel,
            title: 'Mentions légales',
            onTap: () => _openLegal(),
          ),

          const Divider(height: 32),

          // App Info Section
          _buildSectionHeader('À propos'),
          _buildListTile(
            icon: Icons.info_outline,
            title: 'Version de l\'application',
            subtitle: _appVersion,
            onTap: () => _showVersionInfo(),
          ),
          _buildListTile(
            icon: Icons.star_outline,
            title: 'Noter l\'application',
            subtitle: 'Donnez-nous votre avis',
            onTap: () => _rateApp(),
          ),
          _buildListTile(
            icon: Icons.share_outlined,
            title: 'Partager l\'application',
            onTap: () => _shareApp(),
          ),

          const Divider(height: 32),

          // Danger Zone
          _buildSectionHeader('Zone de danger', color: Colors.red),
          _buildListTile(
            icon: Icons.logout,
            title: 'Se déconnecter',
            iconColor: Colors.orange,
            onTap: () => _confirmLogout(),
          ),
          _buildListTile(
            icon: Icons.delete_forever,
            title: 'Supprimer mon compte',
            subtitle: 'Action irréversible',
            iconColor: Colors.red,
            textColor: Colors.red,
            onTap: () => _confirmDeleteAccount(),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.grey[600],
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? iconColor,
    Color? textColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? AppTheme.primaryColor),
      title: Text(title, style: TextStyle(color: textColor)),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  String _getLanguageName(String code) {
    switch (code) {
      case 'fr':
        return 'Français';
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      default:
        return 'Français';
    }
  }

  void _showSecuritySettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Sécurité',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Changer le mot de passe'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.forgotPassword);
              },
            ),
            ListTile(
              leading: const Icon(Icons.phonelink_lock),
              title: const Text('Authentification à deux facteurs'),
              subtitle: const Text('Non activée'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Appareils connectés'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité à venir')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showVerificationInfo() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'État de la vérification',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _VerificationItem(
              title: 'Email',
              isVerified: authProvider.user?.emailVerified ?? false,
            ),
            _VerificationItem(
              title: 'Identité',
              isVerified: false,
            ),
            _VerificationItem(
              title: 'Assurance professionnelle',
              isVerified: false,
            ),
            const SizedBox(height: 16),
            const Text(
              'Les comptes vérifiés bénéficient d\'une meilleure visibilité.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Téléversement de documents à venir')),
                );
              },
              child: const Text('Compléter la vérification'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choisir la langue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            RadioListTile(
              title: const Text('Français'),
              value: 'fr',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile(
              title: const Text('English'),
              value: 'en',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Traduction à venir')),
                );
              },
            ),
            RadioListTile(
              title: const Text('Español'),
              value: 'es',
              groupValue: _language,
              onChanged: (value) {
                setState(() => _language = value!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Traduction à venir')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gestion des paiements à venir avec Stripe')),
    );
  }

  void _showPaymentHistory() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Historique des paiements à venir')),
    );
  }

  void _showBankAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Configuration bancaire à venir avec Stripe Connect')),
    );
  }

  void _openHelpCenter() async {
    final uri = Uri.parse('https://uncomoununesalle.fr/help');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'support@uncomoununesalle.fr',
      query: 'subject=Support UnCoachUneSalle',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _reportBug() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signaler un problème'),
        content: const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Décrivez le problème rencontré...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Merci pour votre signalement !')),
              );
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }

  void _openTerms() async {
    final uri = Uri.parse('https://uncomoununesalle.fr/terms');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openPrivacy() async {
    final uri = Uri.parse('https://uncomoununesalle.fr/privacy');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openLegal() async {
    final uri = Uri.parse('https://uncomoununesalle.fr/legal');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showVersionInfo() {
    showAboutDialog(
      context: context,
      applicationName: 'UnCoachUneSalle',
      applicationVersion: _appVersion,
      applicationIcon: const FlutterLogo(size: 48),
      children: const [
        Text('La marketplace des installations sportives pour les coachs.'),
        SizedBox(height: 16),
        Text('© 2026 UnCoachUneSalle. Tous droits réservés.'),
      ],
    );
  }

  void _rateApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Redirection vers le store...')),
    );
  }

  void _shareApp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Partage de l\'application...')),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer votre compte ?'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cette action est IRRÉVERSIBLE et supprimera :'),
            SizedBox(height: 12),
            Text('• Votre profil et vos données personnelles'),
            Text('• Vos réservations et historique'),
            Text('• Vos messages et conversations'),
            Text('• Vos avis et notes'),
            SizedBox(height: 12),
            Text(
              'Les données de paiement seront conservées 6 ans conformément à la législation.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showDeleteAccountConfirmation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation finale'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Tapez "SUPPRIMER" pour confirmer la suppression de votre compte.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'SUPPRIMER',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text == 'SUPPRIMER') {
                Navigator.pop(context);
                // In a real app, this would call the delete account API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fonctionnalité RGPD à implémenter côté serveur')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Texte incorrect')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer définitivement'),
          ),
        ],
      ),
    );
  }
}

class _VerificationItem extends StatelessWidget {
  final String title;
  final bool isVerified;

  const _VerificationItem({
    required this.title,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isVerified ? Icons.check_circle : Icons.pending,
        color: isVerified ? Colors.green : Colors.orange,
      ),
      title: Text(title),
      subtitle: Text(
        isVerified ? 'Vérifié' : 'Non vérifié',
        style: TextStyle(color: isVerified ? Colors.green : Colors.orange),
      ),
    );
  }
}
