import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../branding/resolved_brand_config.dart';

class AppStrings {
  const AppStrings._(this.locale);
  static const AppStrings _fallbackPortuguese = AppStrings._(Locale('pt'));

  final Locale locale;

  static const supportedLocales = <Locale>[
    Locale('pt'),
    Locale('en'),
  ];

  static const localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppStringsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppStrings of(BuildContext context) {
    return maybeOf(context) ?? _fallbackPortuguese;
  }

  static AppStrings? maybeOf(BuildContext context) {
    return Localizations.of<AppStrings>(context, AppStrings);
  }

  bool get isPortuguese => locale.languageCode.toLowerCase().startsWith('pt');

  String tr(String portuguese, [String? english]) {
    return isPortuguese ? portuguese : (english ?? portuguese);
  }

  String branded(
    ResolvedBrandConfig config, {
    required String key,
    required String portuguese,
    String? english,
  }) {
    if (isPortuguese) {
      return config.copyText(key, defaultValue: portuguese);
    }
    return english ?? portuguese;
  }

  String get inspection => isPortuguese ? 'Vistoria' : 'Inspection';
  String get startInspection =>
      isPortuguese ? 'Iniciar Vistoria' : 'Start Inspection';
  String get review => isPortuguese ? 'Revisar' : 'Review';
  String get finalReview =>
      isPortuguese ? 'Revisão final' : 'Final review';
  String get finalInspectionReview =>
      isPortuguese ? 'Revisão final da vistoria' : 'Final inspection review';
  String get thereArePendingItems =>
      isPortuguese ? 'Existem pendências' : 'There are pending items';
  String pendingItemsDialog(int count) => isPortuguese
      ? 'Ainda existem $count item(ns) com pendência. Deseja finalizar a vistoria mesmo assim?'
      : 'There are still $count pending item(s). Do you want to complete the inspection anyway?';
  String get back => isPortuguese ? 'Voltar' : 'Back';
  String get completeAnyway =>
      isPortuguese ? 'Finalizar mesmo assim' : 'Complete anyway';
  String get subtypeTargetItem =>
      isPortuguese ? 'Subtipo / Local' : 'Subtype / Target item';
  String get targetQualifier =>
      isPortuguese ? 'Elemento' : 'Target qualifier';
  String get material => 'Material';
  String get conditionState =>
      isPortuguese ? 'Estado' : 'Condition state';
  String pendingItemsLabel(int count) => isPortuguese
      ? '$count pendência(s)'
      : '$count pending item(s)';
  String get noPendingItemsAtStage => isPortuguese
      ? 'Sem pendências nesta etapa'
      : 'No pending items at this stage';
  String get noPendingAdjustmentsAtStage => isPortuguese
      ? 'Nenhum ajuste pendente nesta etapa.'
      : 'No pending adjustments at this stage.';
  String get goToPendingItem =>
      isPortuguese ? 'Ir para pendência' : 'Go to pending item';
  String get pendingNavigationHint => isPortuguese
      ? 'Toque em "Ir para pendência" para navegar direto ao ponto de ajuste.'
      : 'Use "Go to pending item" to navigate directly to the required adjustment.';
  String checkInProgress(int done, int total) =>
      'Check-In $done/$total';
  String captureProgress(int done, int total) =>
      isPortuguese ? 'Captura $done/$total' : 'Capture $done/$total';
  String reviewProgress(int done, int total) =>
      isPortuguese ? 'Revisão $done/$total' : 'Review $done/$total';
  String finalizationProgress(int done, int total) => isPortuguese
      ? 'Finalização $done/$total'
      : 'Finalization $done/$total';
  String get technicalJustification =>
      isPortuguese ? 'Justificativa técnica' : 'Technical justification';
  String get finalNote =>
      isPortuguese ? 'Observação final' : 'Final note';
  String get finalNoteHelper => isPortuguese
      ? 'Use este campo para registrar a conferência final.'
      : 'Use this field to record the final verification.';
  String attentionPendingItems(int count) => isPortuguese
      ? 'Atenção: ainda existem $count pendência(s).'
      : 'Attention: there are still $count pending item(s).';
  String get fillTechnicalJustification => isPortuguese
      ? 'Preencha a justificativa técnica para concluir a vistoria.'
      : 'Fill in the technical justification to complete the inspection.';
  String get capture => isPortuguese ? 'Coleta' : 'Capture';
  String get updateGps => isPortuguese ? 'Atualizar GPS' : 'Update GPS';
  String get gpsValidationUpdated => isPortuguese
      ? 'Validação de GPS atualizada.'
      : 'GPS validation updated.';
  String get gpsValidatedSuccessfully => isPortuguese
      ? 'GPS validado com sucesso.'
      : 'GPS validated successfully.';
  String get whatAmIAnalyzing => isPortuguese
      ? 'O que estou analisando?'
      : 'What am I analyzing?';
  String get photoCapturedSuccessfully => isPortuguese
      ? 'Foto capturada com sucesso.'
      : 'Photo captured successfully.';
  String get galleryImageLinkedSuccessfully => isPortuguese
      ? 'Imagem da galeria vinculada com sucesso.'
      : 'Gallery image linked successfully.';
  String get noEnvironmentSelected => isPortuguese
      ? 'Nenhum ambiente selecionado.'
      : 'No environment selected.';
  String operationFailed(Object error) => isPortuguese
      ? 'Falha na operacao: $error'
      : 'Operation failed: $error';
  String get environment => isPortuguese ? 'Ambiente' : 'Environment';
  String get materialLabel => isPortuguese ? 'Material' : 'Material';
  String get conditionStateLabel =>
      isPortuguese ? 'Estado de conservacao' : 'Condition state';
  String get whereAmI => isPortuguese ? 'Onde estou?' : 'Where am I?';
  String get environmentDoesNotExist => isPortuguese
      ? 'Ambiente nao existe'
      : 'Environment does not exist';
  String get whichEnvironmentFound => isPortuguese
      ? 'Qual ambiente encontrou?'
      : 'Which environment did you find?';
  String get saveUnconfiguredEnvironment => isPortuguese
      ? 'Salvar ambiente nao configurado'
      : 'Save unconfigured environment';
  String get change => isPortuguese ? 'Trocar' : 'Change';
  String auditInfo(
    String radiusMeters,
    String latitude,
    String longitude,
  ) =>
      isPortuguese
          ? 'Auditoria ativa • raio permitido ${radiusMeters}m • check-in $latitude, $longitude'
          : 'Active audit • allowed radius ${radiusMeters}m • check-in $latitude, $longitude';
  String get enableDeviceGpsForEvidence => isPortuguese
      ? 'Para registrar evidencias da vistoria, ative o GPS do aparelho.'
      : 'To register inspection evidence, enable the device GPS.';
  String get enable => isPortuguese ? 'Ativar' : 'Enable';
  String get registerEvidence =>
      isPortuguese ? 'Registrar evidencia' : 'Register evidence';
  String get processing => isPortuguese ? 'Processando...' : 'Processing...';
  String get gallery => isPortuguese ? 'Galeria' : 'Gallery';
  String get captureBlockedGpsDisabled => isPortuguese
      ? 'Captura bloqueada enquanto o GPS estiver desligado.'
      : 'Capture blocked while GPS is disabled.';
  String get noEvidenceForEnvironment => isPortuguese
      ? 'Nenhuma evidencia registrada neste ambiente.'
      : 'No evidence registered for this environment.';
  String get evidenceForEnvironment => isPortuguese
      ? 'Evidencias deste ambiente'
      : 'Evidence for this environment';
  String get undefinedTargetItem => isPortuguese
      ? 'Sem elemento definido'
      : 'No target item defined';
  String evidenceSourceLabel(bool fromCamera) =>
      isPortuguese ? (fromCamera ? 'Camera' : 'Galeria') : (fromCamera ? 'Camera' : 'Gallery');
  String coordinatesLabel(String latitude, String longitude) =>
      isPortuguese
          ? 'Lat $latitude • Lng $longitude'
          : 'Lat $latitude • Lng $longitude';
  String get smartGuidanceTitle => isPortuguese
      ? 'Plano inteligente da vistoria'
      : 'Smart inspection plan';
  String smartGuidanceStartPoint(String context) => isPortuguese
      ? 'Inicie a vistoria por $context.'
      : 'Start the inspection from $context.';
  String smartGuidanceEnvironment(String environment) => isPortuguese
      ? 'Priorize o ambiente $environment.'
      : 'Prioritize the $environment environment.';
  String smartGuidanceStartPointWithEnvironment(
    String context,
    String environment,
  ) =>
      isPortuguese
          ? 'Inicie por $context e priorize o ambiente $environment.'
          : 'Start from $context and prioritize the $environment environment.';
  String smartGuidanceEvidenceCount(int count) => isPortuguese
      ? 'Registre pelo menos $count evidência(s) neste fluxo.'
      : 'Capture at least $count evidence item(s) in this flow.';
  String smartGuidanceMinimumPhotos(int count) => isPortuguese
      ? 'Mínimo de $count foto(s) para esta evidência.'
      : 'Minimum of $count photo(s) for this evidence.';
  String smartCaptureHintRoute(String route) => isPortuguese
      ? 'Próxima evidência sugerida: $route.'
      : 'Next suggested evidence: $route.';
  String smartCaptureSequenceProgress(int done, int total) => isPortuguese
      ? 'Roteiro $done/$total concluído.'
      : 'Plan progress $done/$total completed.';
  String get smartGuidanceManualReview => isPortuguese
      ? 'Este job exige revisão manual ao longo do fluxo.'
      : 'This job requires manual review during the flow.';
}

class AppStringsDelegate extends LocalizationsDelegate<AppStrings> {
  const AppStringsDelegate();

  @override
  bool isSupported(Locale locale) =>
      AppStrings.supportedLocales.any(
        (supported) => supported.languageCode == locale.languageCode,
      );

  @override
  Future<AppStrings> load(Locale locale) async => AppStrings._(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppStrings> old) => false;
}
