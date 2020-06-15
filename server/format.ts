export const dateFormat = new Intl.DateTimeFormat("en", {
  year: "numeric",
  month: "short",
  day: "2-digit",
});

export const numberFormat = new Intl.NumberFormat("en-US", {
  minimumFractionDigits: 2,
});
