package com.appbackoffice.api.security;

public final class TenantSecurityContextHolder {

    private static final ThreadLocal<TenantSecurityContext> CONTEXT = new ThreadLocal<>();

    private TenantSecurityContextHolder() {
    }

    public static TenantSecurityContext getContext() {
        return CONTEXT.get();
    }

    public static void setContext(TenantSecurityContext context) {
        CONTEXT.set(context);
    }

    public static void clear() {
        CONTEXT.remove();
    }
}
