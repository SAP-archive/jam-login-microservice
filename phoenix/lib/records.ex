defmodule LoginProxy.Records do
  require Record
  import Record, only: [defrecord: 2, extract: 2]

  # def records for each type in the hrl file
  defrecord :esaml_sp, extract(:esaml_sp, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_org, extract(:esaml_org, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_contact, extract(:esaml_contact, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_idp_metadata, extract(:esaml_idp_metadata, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_subject, extract(:esaml_subject, from_lib: "esaml/include/esaml.hrl")
  defrecord :esaml_authnreq, extract(:esaml_authnreq, from_lib: "esaml/include/esaml.hrl")
  # The next record has a nested attribute which extract fails on, so just define it here.
  defrecord :esaml_assertion,
    version: '2.0',
    issue_instant: '',
    recipient: '',
    issuer: '',
    subject: extract(:esaml_subject, from_lib: "esaml/include/esaml.hrl"),
    conditions: [],
    attributes: []
end
