part of lighthouse_markdown;

markdownOpenLinkOnTap(
    final String text, final String? href, final String title) {
  if (href != null) {
    launchUrlString(href, mode: LaunchMode.externalApplication);
  }
}
