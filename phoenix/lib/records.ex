defmodule LoginProxy.Records do
  require Record
  import Record, only: [defrecord: 2, extract: 2]

  # def records for each type in the hrl file
  defrecord :esaml_sp, extract(:esaml_sp, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_org, extract(:esaml_org, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_contact, extract(:esaml_contact, from_lib: "esaml/include/esaml.hrl")
end
