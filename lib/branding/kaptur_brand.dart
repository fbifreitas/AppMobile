import 'package:flutter/material.dart';

import '../config/brand_feature_flags.dart';
import '../config/product_mode.dart';
import 'brand_manifest.dart';

/// Manifesto da marca Kaptur — app principal marketplace.
///
/// Identidade: azul corporativo forte, linguagem de proposta/oportunidade,
/// geofence obrigatório, swipe em ações críticas, bloco de propostas ativo.
const BrandManifest kapturManifest = BrandManifest(
  brandId: 'kaptur',
  appName: 'Kaptur',
  primaryColor: Color(0xFF0D3B92),
  secondaryColor: Color(0xFF1A56C4),
  accentColor: Color(0xFF2979FF),
  logoAsset: 'assets/brands/kaptur/logo.png',
  iconAsset: 'assets/brands/kaptur/icon.png',
  productMode: ProductMode.marketplace,
  featureFlags: BrandFeatureFlags.kaptur,
  copyOverrides: {
    'jobs_section_title': 'MEUS JOBS DE HOJE',
    'proposals_section_title': 'NOVAS PROPOSTAS',
    'home_subtitle': 'Seu painel operacional de hoje',
    'login_welcome': 'Bem-vindo ao Kaptur',
    'proposal_accept_label': 'ACEITAR PROPOSTA',
    'proposal_swipe_label': 'DESLIZE PARA ACEITAR',
    'job_start_label': 'Iniciar vistoria',
    'job_resume_label': 'Retomar vistoria',
    'job_start_blocked_label': 'Fora do raio',
  },
);
