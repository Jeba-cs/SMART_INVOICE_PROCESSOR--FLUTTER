extension CurrencyFormat on num {
  String toCurrencyString() {
    return toStringAsFixed(2).replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
    );
  }
}
