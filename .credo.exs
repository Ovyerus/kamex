%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "priv/", "test/"],
        excluded: []
      },
      color: true,
      checks: [
        {Credo.Check.Refactor.Nesting, false},
        {Credo.Check.Refactor.CyclomaticComplexity, false},
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999}
      ]
    }
  ]
}
