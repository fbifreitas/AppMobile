package com.appbackoffice.api.config;

import com.appbackoffice.api.contract.ApiContractException;
import com.appbackoffice.api.contract.ErrorSeverity;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;

import java.util.EnumMap;
import java.util.EnumSet;
import java.util.Map;

@Component
public class ConfigPolicyService {

    private final Map<ActorRole, EnumSet<ConfigAction>> permissions = new EnumMap<>(ActorRole.class);

    public ConfigPolicyService() {
        permissions.put(ActorRole.VIEWER, EnumSet.of(ConfigAction.READ));
        permissions.put(ActorRole.OPERATOR, EnumSet.of(ConfigAction.READ, ConfigAction.PUBLISH));
        permissions.put(ActorRole.TENANT_ADMIN, EnumSet.allOf(ConfigAction.class));
        permissions.put(ActorRole.SUPPORT, EnumSet.of(ConfigAction.READ, ConfigAction.ROLLBACK));
    }

    public void assertAllowed(ActorRole actorRole, ConfigAction action) {
        if (permissions.getOrDefault(actorRole, EnumSet.noneOf(ConfigAction.class)).contains(action)) {
            return;
        }

        throw new ApiContractException(
                HttpStatus.FORBIDDEN,
                "POLICY_FORBIDDEN",
                "Perfil %s nao possui permissao para %s pacote de configuracao.".formatted(actorRole.name().toLowerCase(), action.name().toLowerCase()),
                ErrorSeverity.ERROR,
                "Revise o papel operacional do usuario antes de repetir a operacao.",
                "actorRole=" + actorRole.name().toLowerCase() + ", action=" + action.name().toLowerCase()
        );
    }
}