import 'package:flutter/material.dart';

import '../config/brand_feature_flags.dart';
import '../config/product_mode.dart';
import 'brand_manifest.dart';

/// Manifesto da marca Compass Avaliações — app corporativo.
///
/// Identidade: verde institucional, linguagem operacional sem marketplace,
/// sem propostas, swipe não obrigatório, foco em ordens do dia.
const BrandManifest compassManifest = BrandManifest(
  brandId: 'compass',
  appName: 'Compass Avaliações',
  primaryColor: Color(0xFF1B6B3A),
  secondaryColor: Color(0xFF2E8B57),
  accentColor: Color(0xFF4CAF50),
  logoAsset: 'assets/brands/compass/logo.png',
  iconAsset: 'assets/brands/compass/icon.png',
  productMode: ProductMode.corporate,
  featureFlags: BrandFeatureFlags.compass,
  copyOverrides: {
    'jobs_section_title': 'ORDENS DO DIA',
    'proposals_section_title': 'DEMANDAS DISPONÍVEIS',
    'home_subtitle': 'Seu painel de avaliações',
    'login_welcome': 'Bem-vindo à Compass Avaliações',
    'proposal_accept_label': 'ACEITAR DEMANDA',
    'proposal_swipe_label': 'CONFIRMAR ACEITE',
    'job_start_label': 'Iniciar avaliação',
    'job_resume_label': 'Retomar avaliação',
    'job_start_blocked_label': 'Fora da área',
  },
);
