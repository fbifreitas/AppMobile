import 'package:appmobile/l10n/app_strings.dart';
import 'package:appmobile/models/smart_execution_plan.dart';
import 'package:appmobile/services/smart_execution_plan_guidance_presenter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('builds operational guidance from execution plan', (
    tester,
  ) async {
    const presenter = SmartExecutionPlanGuidancePresenter.instance;
    const plan = SmartExecutionPlan(
      snapshotId: 1,
      caseId: 10,
      status: 'PUBLISHED',
      jobId: 'job-1',
      initialContext: 'Rua',
      firstEnvironment: 'Fachada',
      requiredEvidenceCount: 3,
      requiresManualReview: true,
      capturePlan: [
        SmartExecutionCapturePlanItem(
          macroLocal: 'Rua',
          environment: 'Fachada',
          element: 'Porta principal',
          required: true,
          minPhotos: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: Builder(
          builder: (context) {
            final guidance = presenter.resolve(
              plan: plan,
              strings: AppStrings.of(context),
            );

            expect(guidance, isNotNull);
            expect(guidance!.requiresAttention, isTrue);
            expect(
              guidance.items,
              contains('Inicie por Rua e priorize o ambiente Fachada.'),
            );
            expect(
              guidance.items,
              contains('Registre pelo menos 3 evidência(s) neste fluxo.'),
            );
            expect(
              guidance.items,
              contains('Este job exige revisão manual ao longo do fluxo.'),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('includes alternative subtype candidates in guidance', (
    tester,
  ) async {
    const presenter = SmartExecutionPlanGuidancePresenter.instance;
    const plan = SmartExecutionPlan(
      snapshotId: 2,
      caseId: 20,
      status: 'PUBLISHED',
      jobId: 'job-2',
      initialAssetType: 'Urbano',
      initialAssetSubtype: 'Apartamento',
      candidateAssetSubtypes: ['Apartamento', 'Duplex'],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: Builder(
          builder: (context) {
            final guidance = presenter.resolve(
              plan: plan,
              strings: AppStrings.of(context),
            );

            expect(guidance, isNotNull);
            expect(
              guidance!.items,
              contains(
                'Classificacao sugerida: Urbano > Apartamento. Alternativas: Duplex',
              ),
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('returns null when execution plan has no visible guidance', (
    tester,
  ) async {
    const presenter = SmartExecutionPlanGuidancePresenter.instance;
    const plan = SmartExecutionPlan(
      snapshotId: 1,
      caseId: 10,
      status: 'PUBLISHED',
      jobId: 'job-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: Builder(
          builder: (context) {
            final guidance = presenter.resolve(
              plan: plan,
              strings: AppStrings.of(context),
            );

            expect(guidance, isNull);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });

  testWidgets('builds capture hint from required capture plan item', (
    tester,
  ) async {
    const presenter = SmartExecutionPlanGuidancePresenter.instance;
    const plan = SmartExecutionPlan(
      snapshotId: 1,
      caseId: 10,
      status: 'PUBLISHED',
      jobId: 'job-1',
      requiresManualReview: true,
      capturePlan: [
        SmartExecutionCapturePlanItem(
          macroLocal: 'Street',
          environment: 'Fachada',
          element: 'Porta principal',
          required: true,
          minPhotos: 2,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('pt'),
        localizationsDelegates: AppStrings.localizationsDelegates,
        supportedLocales: AppStrings.supportedLocales,
        home: Builder(
          builder: (context) {
            final hint = presenter.resolveCaptureHint(
              plan: plan,
              strings: AppStrings.of(context),
            );

            expect(
              hint,
              'Plano inteligente da vistoria: Próxima evidência sugerida: Rua > Fachada > Porta principal. Roteiro 0/1 concluído. Mínimo de 2 foto(s) para esta evidência. Este job exige revisão manual ao longo do fluxo.',
            );
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  });
}
