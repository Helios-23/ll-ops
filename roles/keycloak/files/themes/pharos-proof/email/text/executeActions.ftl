<#ftl output_format="plainText">
<#assign requiredActionsText><#if requiredActions??><#list requiredActions><#items as action>${msg("requiredAction.${action}")}<#sep>, </#items></#list></#if></#assign>
<#assign expirationText=linkExpirationFormatter(linkExpiration)>
<#if linkExpiration == 1440><#assign expirationText="24 hours"></#if>
${msg("executeActionsBody",link,linkExpiration,realmName,requiredActionsText,expirationText)}
