/// The `VisitPurpose` enum, mirrored. The server rejects anything else with
/// a 422, so these values must stay in step with the CRM's enum.
enum VisitPurpose {
  introduction('introduction', 'Introduction'),
  productDetailing('product_detailing', 'Product detailing'),
  sampleDrop('sample_drop', 'Sample drop'),
  orderFollowUp('order_follow_up', 'Order follow-up'),
  paymentFollowUp('payment_follow_up', 'Payment follow-up'),
  courtesy('courtesy', 'Courtesy call'),
  other('other', 'Other');

  const VisitPurpose(this.value, this.label);

  /// What goes on the wire.
  final String value;

  /// What the rep reads.
  final String label;

  static VisitPurpose? fromValue(String? value) {
    for (final purpose in VisitPurpose.values) {
      if (purpose.value == value) return purpose;
    }

    return null;
  }
}
