import { useState } from "react";
import { useMutation, useQuery } from "@tanstack/react-query";
import { getUsers, updateUser } from "@/lib/api";
import { toast } from "sonner";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import GlobalSearch from "@/components/global/GlobalSearch";
import Loader from "@/components/global/Loader";
import { navConfig } from "@/components/navigation/nav-config";
import type { Role } from "@/types";

export function meta() {
  return [{ title: "Roles & Permissions | Ask Musawo" }];
}

const ROLES: Role[] = ["admin", "doctor", "nurse", "pharmacist", "lab_tech", "patient"];

function permissionsFor(role: Role) {
  const sections = [...navConfig.navMain, ...navConfig.navAdmin, ...navConfig.navSecondary];
  return sections.filter((item) => item.allowedRoles.includes(role));
}

export default function RolesSettings() {
  const [search, setSearch] = useState("");

  const { data, isLoading, isError, refetch } = useQuery({
    queryKey: ["users", "all", "roles-settings"],
    queryFn: () => getUsers({ role: "all", limit: 100 }),
  });

  const mutation = useMutation({
    mutationFn: updateUser,
    onSuccess: () => {
      toast.success("Role updated");
      refetch();
    },
    onError: (e: any) => toast.error(e.message || "Failed to update role"),
  });

  if (isLoading) {
    return (
      <div className="flex justify-center items-center min-h-[60vh]">
        <Loader label="Loading Users..." />
      </div>
    );
  }
  if (isError) {
    return (
      <div className="p-10 text-center text-red-500">
        Failed to load users.
      </div>
    );
  }

  const users = (data?.res || []).filter((u) =>
    u.name.toLowerCase().includes(search.toLowerCase()),
  );

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-black tracking-tight">
          Roles & Permissions
        </h1>
        <p className="text-slate-500 font-medium">
          Assign roles to users and review what each role can access.
        </p>
      </div>

      <Card className="card shadow-sm">
        <CardHeader className="flex flex-row items-center justify-between">
          <div>
            <CardTitle>User Roles</CardTitle>
            <CardDescription>
              Changing a role immediately changes what that user can access.
            </CardDescription>
          </div>
          <GlobalSearch search={search} setSearch={setSearch} title="users" />
        </CardHeader>
        <CardContent>
          <div className="rounded-md border border-zinc-300 dark:border-zinc-700">
            <Table>
              <TableHeader>
                <TableRow>
                  <TableHead>User</TableHead>
                  <TableHead>Email</TableHead>
                  <TableHead>Role</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {users.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={3} className="text-center h-24 text-muted-foreground">
                      No users found.
                    </TableCell>
                  </TableRow>
                ) : (
                  users.map((u) => (
                    <TableRow key={u.id}>
                      <TableCell className="font-medium">
                        <div className="flex items-center gap-3">
                          <Avatar className="h-8 w-8">
                            <AvatarImage src={u.image || ""} />
                            <AvatarFallback>
                              {u.name.split(" ").map((n) => n[0]).join("")}
                            </AvatarFallback>
                          </Avatar>
                          {u.name}
                        </div>
                      </TableCell>
                      <TableCell>{u.email}</TableCell>
                      <TableCell>
                        <Select
                          value={u.role}
                          onValueChange={(role) =>
                            mutation.mutate({
                              userId: u.id,
                              userData: { role: role as Role },
                            })
                          }
                        >
                          <SelectTrigger className="w-40">
                            <SelectValue />
                          </SelectTrigger>
                          <SelectContent>
                            {ROLES.map((r) => (
                              <SelectItem key={r} value={r} className="capitalize">
                                {r.replace("_", " ")}
                              </SelectItem>
                            ))}
                          </SelectContent>
                        </Select>
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      <Card className="card shadow-sm">
        <CardHeader>
          <CardTitle>Access Matrix</CardTitle>
          <CardDescription>
            What each role can currently see in the platform sidebar.
          </CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
          {ROLES.map((role) => (
            <div
              key={role}
              className="rounded-lg border border-zinc-200 dark:border-zinc-800 p-4"
            >
              <p className="font-bold capitalize mb-2">{role.replace("_", " ")}</p>
              <ul className="space-y-1 text-sm text-slate-600 dark:text-slate-300">
                {permissionsFor(role).map((item) => (
                  <li key={item.title}>{item.title}</li>
                ))}
              </ul>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
