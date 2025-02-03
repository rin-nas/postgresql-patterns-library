-- Based on source: https://www.cybertec-postgresql.com/en/postgresql-get-member-roles-and-permissions/

CREATE OR REPLACE VIEW pg_role_members AS
WITH RECURSIVE x AS
(
    SELECT member::regrole,
         roleid::regrole AS role,
         member::regrole || ' -> ' || roleid::regrole AS path,
         1 as depth
    FROM pg_auth_members AS m
    UNION ALL
    SELECT x.member::regrole,
         m.roleid::regrole,
         x.path || ' -> ' || m.roleid::regrole,
         x.depth + 1
    FROM pg_auth_members AS m
    JOIN x ON m.member = x.role
)
SELECT *
FROM x
ORDER BY member::text, depth, role::text;
  
COMMENT ON VIEW pg_role_members IS 'Role membership tree';
