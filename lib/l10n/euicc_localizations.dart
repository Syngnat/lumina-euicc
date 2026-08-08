import '../models/euicc_models.dart';
import 'generated/app_localizations.dart';

typedef LocalizedCompatibilityItem = ({String title, String detail});

extension EuiccPresentationLocalizations on AppLocalizations {
  String euiccChannelLabel(EuiccChannelInfo channel) {
    switch (channel.type.toLowerCase()) {
      case 'omapi':
        return omapiChannelLabel(
          channel.slotId,
          channel.portId,
          channel.seId,
        );
      case 'usb':
        return usbChannelLabel(
          channel.slotId,
          channel.portId,
          channel.seId,
        );
      case 'mock':
        return mockChannelLabel;
      default:
        return channel.label;
    }
  }

  LocalizedCompatibilityItem localizeCompatibilityItem(
    CompatibilityItem item,
  ) {
    final fallback = (title: item.title, detail: item.detail);
    final arguments = item.arguments;

    switch (item.code) {
      case 'app_identity':
        final packageName = _stringArgument(arguments, 'packageName');
        final certificates =
            _stringListArgument(arguments, 'signingCertificateSha1s');
        if (packageName == null || certificates == null) return fallback;
        return (
          title: compatibilityAppIdentityTitle,
          detail: certificates.isEmpty
              ? compatibilityAppIdentityUnavailable(packageName)
              : compatibilityAppIdentityAvailable(
                  packageName,
                  certificates.join(listSeparator),
                ),
        );
      case 'lpa_port_failed':
        final slotId = _intArgument(arguments, 'slotId');
        final portId = _intArgument(arguments, 'portId');
        final failureType = _stringArgument(arguments, 'failureType');
        if (slotId == null || portId == null || failureType == null) {
          return fallback;
        }
        return (
          title: compatibilityLpaPortTitle(slotId, portId),
          detail: compatibilityLpaPortFailed(failureType),
        );
      case 'lpa_probe_failed':
        final failureType = _stringArgument(arguments, 'failureType');
        if (failureType == null) return fallback;
        return (
          title: compatibilityLpaProbeTitle,
          detail: compatibilityLpaProbeFailed(failureType),
        );
      case 'omapi_present':
        return (
          title: compatibilityOmapiTitle,
          detail: compatibilityOmapiPresent,
        );
      case 'omapi_missing':
        return (
          title: compatibilityOmapiTitle,
          detail: compatibilityOmapiMissing,
        );
      case 'omapi_service_failed':
        final failureType = _stringArgument(arguments, 'failureType');
        if (failureType == null) return fallback;
        return (
          title: compatibilityOmapiServiceTitle,
          detail: compatibilityOmapiServiceFailed(failureType),
        );
      case 'omapi_slot_authorized':
      case 'omapi_slot_access_denied':
      case 'omapi_slot_isdr_unavailable':
      case 'omapi_slot_failed':
        final slotId = _intArgument(arguments, 'slotId');
        if (slotId == null) return fallback;
        final detail = switch (item.code) {
          'omapi_slot_authorized' => compatibilityOmapiSlotAuthorized,
          'omapi_slot_access_denied' =>
            compatibilityOmapiSlotAccessDenied(slotId),
          'omapi_slot_isdr_unavailable' =>
            compatibilityOmapiSlotIsdrUnavailable(slotId),
          'omapi_slot_failed' => _localizedOmapiSlotFailure(
              arguments,
              fallback.detail,
            ),
          _ => fallback.detail,
        };
        return (
          title: compatibilityOmapiSlotTitle(slotId),
          detail: detail,
        );
      case 'omapi_no_uicc_readers':
        return (
          title: compatibilityOmapiReadersTitle,
          detail: compatibilityOmapiNoReaders,
        );
      case 'euicc_ports_found':
        final ports = _portArguments(arguments);
        if (ports == null || ports.isEmpty) return fallback;
        return (
          title: compatibilityEuiccPortsTitle,
          detail: ports
              .map(
                (port) => compatibilityEuiccPort(
                  port.slotId,
                  port.portId,
                ),
              )
              .join(listSeparator),
        );
      case 'euicc_ports_missing':
        return (
          title: compatibilityEuiccPortsTitle,
          detail: compatibilityEuiccPortsMissing,
        );
      case 'lpa_channel_valid':
        return (
          title: compatibilityLpaChannelTitle,
          detail: compatibilityLpaChannelValid,
        );
      case 'lpa_channel_invalid':
        return (
          title: compatibilityLpaChannelTitle,
          detail: compatibilityLpaChannelInvalid,
        );
      case 'rootless_access_ready':
        return (
          title: compatibilityRootlessTitle,
          detail: compatibilityRootlessReady,
        );
      case 'rootless_ara_m_required':
        return (
          title: compatibilityRootlessTitle,
          detail: compatibilityRootlessAraMRequired,
        );
      default:
        return fallback;
    }
  }

  String _localizedOmapiSlotFailure(
    Map<String, dynamic> arguments,
    String fallback,
  ) {
    final failureType = _stringArgument(arguments, 'failureType');
    return failureType == null
        ? fallback
        : compatibilityOmapiSlotFailed(failureType);
  }
}

String? _stringArgument(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value == null) return null;
  final text = value.toString();
  return text.isEmpty ? null : text;
}

int? _intArgument(Map<String, dynamic> arguments, String key) {
  final value = arguments[key];
  if (value is int) return value;
  return value == null ? null : int.tryParse(value.toString());
}

List<String>? _stringListArgument(
  Map<String, dynamic> arguments,
  String key,
) {
  final value = arguments[key];
  if (value is! List) return null;
  return value.map((entry) => entry.toString()).toList(growable: false);
}

List<({int slotId, int portId})>? _portArguments(
  Map<String, dynamic> arguments,
) {
  final value = arguments['ports'];
  if (value is! List) return null;
  final ports = <({int slotId, int portId})>[];
  for (final entry in value) {
    if (entry is! Map) return null;
    final map = Map<String, dynamic>.from(entry);
    final slotId = _intArgument(map, 'slotId');
    final portId = _intArgument(map, 'portId');
    if (slotId == null || portId == null) return null;
    ports.add((slotId: slotId, portId: portId));
  }
  return ports;
}
