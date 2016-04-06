<%@ page session="true" %>
<%@ page import="org.openid4java.association.AssociationSessionType"%>
<%@ page import="java.util.*" %>
<%@ page import="org.openid4java.discovery.Identifier" %>
<%@ page import="org.openid4java.discovery.DiscoveryInformation" %>
<%@ page import="org.openid4java.message.ax.FetchRequest" %>
<%@ page import="org.openid4java.message.ax.FetchResponse" %>
<%@ page import="org.openid4java.message.ax.AxMessage" %>
<%@ page import="org.openid4java.message.*" %>
<%@ page import="org.openid4java.OpenIDException" %>
<%@ page import="java.io.IOException" %>
<%@ page import="javax.servlet.http.HttpSession" %>
<%@ page import="javax.servlet.http.HttpServletRequest" %>
<%@ page import="javax.servlet.http.HttpServletResponse" %>
<%@ page import="org.openid4java.consumer.ConsumerManager" %>
<%@ page import="org.openid4java.consumer.InMemoryConsumerAssociationStore" %>
<%@ page import="org.openid4java.consumer.InMemoryNonceVerifier" %>
<%@ page import="nics.openid.idp.EndpointServlet" %>

<%
            // README:
            // Set the returnToUrl string to the appropriate value for this JSP
            // Since you may be deployed behind apache, etc, the jsp has no real idea what the
            // absolute URI is to get back here.

            Object o = pageContext.getAttribute("consumermanager", PageContext.APPLICATION_SCOPE);
            if (o == null) {
                ConsumerManager newmgr = new ConsumerManager();
                newmgr.setAssociations(new InMemoryConsumerAssociationStore());
                newmgr.setNonceVerifier(new InMemoryNonceVerifier(5000));
                newmgr.setMinAssocSessEnc(AssociationSessionType.DH_SHA256);
                newmgr.getRealmVerifier().setEnforceRpId(false);
                newmgr.setSocketTimeout(99999999);
                pageContext.setAttribute("consumermanager", newmgr, PageContext.APPLICATION_SCOPE);
            }
            ConsumerManager manager = (ConsumerManager) pageContext.getAttribute("consumermanager", PageContext.APPLICATION_SCOPE);
            //String openid=request.getParameter("openid");
            String openid = EndpointServlet.BASE_URL + "/idp";
            try {
                // determine a return_to URL where your application will receive
                // the authentication responses from the OpenID provider
                // YOU SHOULD CHANGE THIS TO GO TO THE
                //String returnToUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + "/simple-openid/consumer_returnurl.jsp";
                String returnToUrl = request.getScheme() + "://" + request.getServerName() + ":" + request.getServerPort() + "/openid-idp/consumer_redirect.jsp";

                // perform discovery on the user-supplied identifier
                List discoveries = manager.discover(openid);

                // attempt to associate with an OpenID provider
                // and retrieve one service endpoint for authentication
                DiscoveryInformation discovered = manager.associate(discoveries);

                // store the discovery information in the user's session
                session.setAttribute("openid-disco", discovered);

                // obtain a AuthRequest message to be sent to the OpenID provider
                AuthRequest authReq = manager.authenticate(discovered, returnToUrl);

                // Attribute Exchange example: fetching the 'email' attribute
                //FetchRequest fetch = FetchRequest.createFetchRequest();
                //fetch.addAttribute("email",
                // attribute alias
                //       "http://schema.openid.net/contact/email",   // type URI
                //       true);                                      // required

                // attach the extension to the authentication request
                //authReq.addExtension(fetch);

                if (!discovered.isVersion2()) {
                    // Option 1: GET HTTP-redirect to the OpenID Provider endpoint
                    // The only method supported in OpenID 1.x
                    // redirect-URL usually limited ~2048 bytes
                    response.sendRedirect(authReq.getDestinationUrl(true));
                } else {
                    // Option 2: HTML FORM Redirection
                    // Allows payloads > 2048 bytes

                    // <FORM action="OpenID Provider's service endpoint">
                    // see samples/formredirection.jsp for a JSP example
                    //authReq.getOPEndpoint();

                    // build a HTML FORM with the message parameters
                    //authReq.getParameterMap();

%>
<html xmlns="http://www.w3.org/1999/xhtml">
    <head>
        <title>OpenID HTML FORM Redirection</title>
    </head>
    <!--<body onload="document.forms['openid-form-redirection'].submit();">-->
    <body>
        <form name="openid-form-redirection" action="<%= authReq.getOPEndpoint()%>" method="post" accept-charset="utf-8">
            <%
                            Map pm = authReq.getParameterMap();
                            Iterator keyit = pm.keySet().iterator();

                            Object key;
                            Object value;

                            while (keyit.hasNext()) {
                                key = keyit.next();
                                value = pm.get(key);
            %>
            <input type="hidden" name="<%= key%>" value="<%= value%>"/>
            <%
                            }
            %>
            <button type="submit">Continue...</button>
        </form>
    </body>
</html>
<%
                }
            } catch (OpenIDException e) {
                // present error to the user
                e.printStackTrace();
                response.sendError(500);
            }
%>
