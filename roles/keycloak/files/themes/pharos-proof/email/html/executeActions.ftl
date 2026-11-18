<#outputformat "plainText">
<#assign requiredActionsText><#if requiredActions??><#list requiredActions><#items as action>${msg("requiredAction.${action}")}<#sep>, </#sep></#items></#list></#if></#assign>
</#outputformat>
<#assign expirationText=linkExpirationFormatter(linkExpiration)>
<#if linkExpiration == 1440><#assign expirationText="24 hours"></#if>
<#import "template.ftl" as layout>
<@layout.emailLayout>
${kcSanitize(msg("executeActionsBodyHtml",link,linkExpiration,realmName,requiredActionsText,expirationText))?no_esc}
</@layout.emailLayout>
