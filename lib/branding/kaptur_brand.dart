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
    // Seções
    'jobs_section_title': 'MEUS JOBS DE HOJE',
    'proposals_section_title': 'NOVAS PROPOSTAS',
    // Home
    'home_header_subtitle': 'Seu painel operacional de hoje',
    // Login
    'login_welcome': 'Bem-vindo ao Kaptur',
    // Jobs
    'job_start_label': 'INICIAR VISTORIA',
    'job_resume_label': 'RETOMAR VISTORIA',
    'job_start_blocked_label': 'Fora do raio de vistoria.',
    // Propostas
    'proposal_swipe_label': 'DESLIZE PARA ACEITAR',
    'proposal_accept_label': 'ACEITAR PROPOSTA',
    'proposal_snackbar_accept_success': 'Proposta aceita! Job adicionado ao seu dia.',
    'proposal_empty_title': 'Nenhuma proposta disponível no momento.',
  },
);
