package com.appbackoffice.api.intelligence.service;

import com.appbackoffice.api.intelligence.dto.CaptureGatePolicyResponse;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class CaptureGatePolicyService {

    public CaptureGatePolicyResponse resolve(String tenantId) {
        return new CaptureGatePolicyResponse(
                tenantId,
                "capture-gates-v1",
                List.of(
                        new CaptureGatePolicyResponse.GateItem(
                                "CHECKIN_STEP1_COMPLETED",
                                "Check-in 1 concluido",
                                "O vistoriador precisa concluir a etapa 1 para reduzir o menu e contextualizar a captura.",
                                true,
                                "STATIC_POLICY"
                        ),
                        new CaptureGatePolicyResponse.GateItem(
                                "DEVICE_GPS_ENABLED",
                                "GPS do aparelho ativo",
                                "A captura exige GPS ativo para garantir geolocalizacao da evidencia.",
                                true,
                                "STATIC_POLICY"
                        ),
                        new CaptureGatePolicyResponse.GateItem(
                                "LOCATION_PERMISSION_GRANTED",
                                "Permissao de localizacao concedida",
                                "Sem permissao de localizacao o app nao consegue registrar latitude/longitude com timestamp.",
                                true,
                                "STATIC_POLICY"
                        ),
                        new CaptureGatePolicyResponse.GateItem(
                                "CURRENT_POSITION_AVAILABLE",
                                "Posicao atual disponivel",
                                "A camera so pode capturar quando houver coordenada valida no momento da foto.",
                                true,
                                "STATIC_POLICY"
                        )
                )
        );
    }
}
