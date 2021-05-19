create policy organization_member_self_insert on organization_member 
  for insert with check(organization_member.member_id = public.get_current_user_id());

grant update on address to app_user;

create policy owner_update_organization_address on address
  for
    update using (
      exists(
        select 1
        from organization_member
        inner join "party" on party.address_id = address.id
        inner join "organization" on organization.party_id = party.id
        inner join "user" on organization_member.member_id = "user".id
        where organization_member.organization_id = organization.id
        and member_id = public.get_current_user_id()
        and is_owner is true
      )
  );

drop policy if exists owner_update_organization on organization;
create policy owner_update_organization on organization 
  for update to app_user using (
    exists(
      select 1
      from organization_member
      inner join "user" on organization_member.member_id = "user".id
      where organization_member.organization_id = organization.id
      and member_id = public.get_current_user_id()
      and is_owner is true
    )
  );