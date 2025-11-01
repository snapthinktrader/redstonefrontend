import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/app_theme.dart';

class AboutRedStoneScreen extends StatefulWidget {
  final bool scrollToMilestones;
  
  const AboutRedStoneScreen({super.key, this.scrollToMilestones = false});

  @override
  State<AboutRedStoneScreen> createState() => _AboutRedStoneScreenState();
}

class _AboutRedStoneScreenState extends State<AboutRedStoneScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _milestonesKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.scrollToMilestones) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMilestones();
      });
    }
  }

  void _scrollToMilestones() {
    final context = _milestonesKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.mediumColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'About RedStone',
          style: TextStyle(
            color: AppTheme.darkColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // Header Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(40),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.diamond,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'RedStone Platform',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your Trusted Investment Partner',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Overview Section
                  _buildSectionCard(
                    icon: Icons.info_outline,
                    title: 'What is RedStone?',
                    content:
                        'RedStone is a cutting-edge investment platform designed to help you grow your wealth through smart financial strategies. We offer transparent, reliable, and profitable investment opportunities with real-time earnings tracking.',
                  ),

                  const SizedBox(height: 16),

                  // Daily Earnings Section
                  _buildSectionCard(
                    icon: Icons.trending_up,
                    title: 'Daily Earnings System',
                    content: 'Earn passive income based on your deposit level!',
                    children: [
                      const SizedBox(height: 12),
                      _buildBulletPoint(
                        'Variable Daily Rates',
                        'Earn 2% - 5% daily based on your deposit level',
                      ),
                      _buildBulletPoint(
                        'Real-Time Calculation',
                        'Earnings calculated every second for precision',
                      ),
                      _buildBulletPoint(
                        'Automatic Compounding',
                        'Your earnings automatically increase your balance',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        'Deposit-Based Earning Rates',
                        'Higher deposits unlock better daily earning rates! Start with 2% at Basic level and reach up to 5% at Radiant level.',
                      ),
                      const SizedBox(height: 12),
                      _buildDepositLevelCard('Basic', '\$15', '2.0%', const Color(0xFFB87333)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Bronze', '\$50', '2.0%', const Color(0xFFCD7F32)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Silver', '\$300', '2.5%', const Color(0xFFC0C0C0)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Gold', '\$1,000', '3.0%', const Color(0xFFFFD700)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Platinum', '\$2,000', '3.5%', const Color(0xFFE5E4E2)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Diamond', '\$3,500', '4.0%', const Color(0xFFB9F2FF)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Ascendant', '\$5,000', '4.5%', const Color(0xFF9C27B0)),
                      const SizedBox(height: 6),
                      _buildDepositLevelCard('Radiant', '\$10,000', '5.0%', const Color(0xFFFF1744)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Referral System Section
                  _buildSectionCard(
                    icon: Icons.group,
                    title: 'Referral Commission System',
                    content: 'Build your network and earn ongoing commissions!',
                    children: [
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        'How It Works',
                        'Earn commissions based on your referrals\' DAILY EARNINGS (not deposits). Your commission rate increases with more referrals!',
                      ),
                      const SizedBox(height: 12),
                      _buildReferralLevelCard('Level 1', '0', '0%', '0%', const Color(0xFF9E9E9E)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 2', '3', '15%', '2%', const Color(0xFFCD7F32)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 3', '10', '20%', '3%', const Color(0xFFC0C0C0)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 4', '15', '25%', '4%', const Color(0xFFFFD700)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 5', '25', '30%', '5%', const Color(0xFFE5E4E2)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 6', '50', '35%', '6%', const Color(0xFFB9F2FF)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 7', '100', '40%', '7%', const Color(0xFF9C27B0)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 8', '500', '45%', '8%', const Color(0xFFFF6F00)),
                      const SizedBox(height: 6),
                      _buildReferralLevelCard('Level 9', '1,000', '50%', '10%', const Color(0xFFFF1744)),
                      const SizedBox(height: 12),
                      _buildFormulaCard(
                        title: 'Commission Calculation',
                        formula: 'Daily Commission = Referral Daily Earnings × Your Commission Rate',
                        example:
                            'Level 2 (15%) with referral earning \$10/day:\nYour Commission = \$1.50/day',
                      ),
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        'Direct vs Indirect',
                        'Direct commission from your referrals + Indirect commission from their referrals. Two levels deep!',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Milestone Bonuses Section
                  Container(
                    key: _milestonesKey,
                    child: _buildSectionCard(
                      icon: Icons.emoji_events,
                      title: 'Milestone Bonuses - Dual Track System',
                      content: 'Two separate milestone tracks based on referral deposit amounts!',
                    children: [
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        '🎯 How It Works',
                        'Each referral\'s deposit is counted in ONE of two tracks:\n\n'
                        '• Lower Track: Deposits \$0-\$49 (Always claimable)\n'
                        '• Upper Track: Deposits \$50+ (Bronze+ only)\n\n'
                        'Example: If your referral deposits \$45, it counts in Lower Track. '
                        'If they deposit \$99, it counts in Upper Track.',
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '💚 Lower Track (\$0-\$49 Deposits)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Available to ALL users (Basic and above)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMilestoneCard(3, 15),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(10, 30),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(15, 45),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(25, 65),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(50, 100),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(100, 300),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(500, 1000),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(1000, 3500),
                      const SizedBox(height: 16),
                      const Text(
                        '💎 Upper Track (\$50+ Deposits)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF9C27B0),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '🔒 Bronze+ users only (Tracked but locked for Basic)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildMilestoneCard(3, 50),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(10, 100),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(15, 150),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(25, 250),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(50, 750),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(100, 1600),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(500, 5000),
                      const SizedBox(height: 6),
                      _buildMilestoneCard(1000, 10000),
                      const SizedBox(height: 12),
                      _buildInfoBox(
                        '⚡ Key Points',
                        '• Each deposit counts in ONLY ONE track\n'
                        '• Basic users: Lower track only\n'
                        '• Bronze+ users: Can claim BOTH tracks\n'
                        '• Upper track is 2x the lower track rewards!\n'
                        '• Upgrade to Bronze to unlock all tracked upper milestones',
                      ),
                    ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Level Progression Section
                  _buildSectionCard(
                    icon: Icons.stairs,
                    title: 'Dual Level System',
                    content: 'Two independent progression paths!',
                    children: [
                      const SizedBox(height: 12),
                      const Text(
                        '💎 Deposit Levels (For Daily Earnings)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoBox(
                        'How It Works',
                        'Your deposit level determines your daily earning rate (2%-5%). Deposit more to unlock higher rates!',
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '👥 Referral Levels (For Commission Rates)',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildInfoBox(
                        'How It Works',
                        'Your referral level determines your commission rate (0%-50%). Refer more people to increase your commission percentage!',
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Level up in both categories to maximize your earnings!',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Example Scenario
                  _buildSectionCard(
                    icon: Icons.calculate,
                    title: 'Complete Example',
                    content: 'See how the new system works:',
                    children: [
                      const SizedBox(height: 12),
                      _buildExampleStep(
                        '1',
                        'Initial Deposit',
                        'You deposit \$5,000 (Ascendant level)',
                        '\$5,000',
                      ),
                      _buildExampleStep(
                        '2',
                        'Daily Earnings (30 days)',
                        '4.5% daily at Ascendant level',
                        '+\$6,750',
                      ),
                      _buildExampleStep(
                        '3',
                        'Direct Commissions',
                        '10 referrals (Level 3, 20% rate) earning \$50/day total',
                        '+\$300',
                      ),
                      _buildExampleStep(
                        '4',
                        'Indirect Commissions',
                        '5 indirect referrals (3% rate) earning \$25/day total',
                        '+\$22.50',
                      ),
                      _buildExampleStep(
                        '5',
                        'Milestone Bonus',
                        '10 referrals at Bronze+ level',
                        '+\$100',
                      ),
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total After 30 Days:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '\$12,172.50',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.lightbulb,
                              color: AppTheme.primaryColor,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'That\'s a 143% return in just 30 days with the new dual-level system!',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Contact & Support
                  _buildSectionCard(
                    icon: Icons.support_agent,
                    title: 'Support & Contact',
                    children: [
                      const SizedBox(height: 8),
                      _buildContactItem(Icons.email, 'Email',
                          'support@redstone.com', 'support@redstone.com'),
                      _buildContactItem(Icons.phone, 'Phone', '+1 (555) 123-4567',
                          'tel:+15551234567'),
                      _buildContactItem(Icons.language, 'Website',
                          'www.redstone.com', 'https://www.redstone.com'),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Version Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Text(
                          'RedStone Platform',
                          style: TextStyle(
                            color: AppTheme.mediumColor,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Version 2.0.7',
                          style: TextStyle(
                            color: AppTheme.mediumColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '© 2025 RedStone. All rights reserved.',
                          style: TextStyle(
                            color: AppTheme.mediumColor.withValues(alpha: 0.7),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    String? content,
    List<Widget>? children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(icon, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkColor,
                  ),
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 12),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mediumColor,
                height: 1.5,
              ),
            ),
          ],
          if (children != null) ...children,
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String title, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Icon(
              Icons.check_circle,
              color: AppTheme.primaryColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.mediumColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormulaCard({
    required String title,
    required String formula,
    required String example,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.darkColor.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              formula,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Example:',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.mediumColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            example,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mediumColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard({
    required String level,
    required int levelNumber,
    required String commission,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.2),
            color.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Text(
                '$levelNumber',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$level Level',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            '$commission Commission',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(int referrals, int bonus) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withValues(alpha: 0.1),
            AppTheme.primaryColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$referrals',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Referrals',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          const Icon(Icons.arrow_forward, size: 16, color: AppTheme.mediumColor),
          const SizedBox(width: 8),
          Text(
            '\$$bonus Bonus',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String content) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info, color: Colors.blue, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressionCard({
    required String fromLevel,
    required String toLevel,
    required String requirement,
    required String benefit,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.mediumColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                fromLevel,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 8),
              Text(
                toLevel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Requirement: $requirement',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.mediumColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Benefit: $benefit',
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleStep(
    String step,
    String title,
    String description,
    String amount,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mediumColor,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: amount.startsWith('+')
                  ? AppTheme.primaryColor
                  : AppTheme.darkColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String label,
    String value,
    String action,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mediumColor,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 18),
            color: AppTheme.mediumColor,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDepositLevelCard(String level, String deposit, String rate, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.diamond, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  deposit,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mediumColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$rate/day',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralLevelCard(String level, String referrals, String direct, String indirect, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.group, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  level,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  '$referrals referrals',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.mediumColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$direct direct',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
              Text(
                '$indirect indirect',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
