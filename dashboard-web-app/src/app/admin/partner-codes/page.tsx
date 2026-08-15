"use client";

import { useEffect, useState } from "react";
import { toast } from "sonner";
import { Plus, Copy, Check, Trash2, KeyRound } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Badge } from "@/components/ui/badge";

export default function PartnerCodesPage() {
  const [codes, setCodes] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(false);
  const [generating, setGenerating] = useState<boolean>(false);
  const [copiedCode, setCopiedCode] = useState<string | null>(null);
  
  const fetchCodes = async () => {
    setLoading(true);
    try {
      const res = await fetch("http://localhost:5000/api/admin/partner-codes", {
        headers: {
          Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}`
        }
      });
      if (res.ok) {
        const data = await res.json();
        setCodes(data.codes || []);
      }
    } catch {
      toast.error("Failed to load partner codes");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchCodes();
  }, []);

  const handleGenerate = async () => {
    setGenerating(true);
    try {
      const res = await fetch("http://localhost:5000/api/admin/partner-codes", {
        method: "POST",
        headers: {
          Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}`
        }
      });
      if (res.ok) {
        toast.success("Generated new partner code");
        fetchCodes();
      } else {
        toast.error("Failed to generate code");
      }
    } catch {
      toast.error("Error generating code");
    } finally {
      setGenerating(false);
    }
  };

  const handleDelete = async (id: string) => {
    try {
      const res = await fetch(`http://localhost:5000/api/admin/partner-codes/${id}`, {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${localStorage.getItem("admin_token") || ""}`
        }
      });
      if (res.ok) {
        toast.success("Code revoked");
        fetchCodes();
      } else {
        toast.error("Failed to revoke code");
      }
    } catch {
      toast.error("Error revoking code");
    }
  };

  const copyToClipboard = (code: string) => {
    navigator.clipboard.writeText(code);
    setCopiedCode(code);
    toast.success("Code copied to clipboard");
    setTimeout(() => setCopiedCode(null), 2000);
  };

  return (
    <div className="p-8 space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Partner Codes</h1>
          <p className="text-muted-foreground mt-1">
            Generate and manage 2-tier verification codes for onboarding professional videographers.
          </p>
        </div>
        <Button onClick={handleGenerate} disabled={generating}>
          <Plus className="mr-2 h-4 w-4" />
          {generating ? "Generating..." : "Generate New Code"}
        </Button>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Active & Used Codes</CardTitle>
          <CardDescription>
            These codes must be securely provided to trained partners during their onboarding session.
          </CardDescription>
        </CardHeader>
        <CardContent>
          {loading ? (
            <div className="flex justify-center p-8"><p className="text-muted-foreground">Loading codes...</p></div>
          ) : codes.length === 0 ? (
            <div className="text-center py-12">
              <KeyRound className="mx-auto h-12 w-12 text-muted-foreground/50 mb-4" />
              <h3 className="text-lg font-medium">No codes generated</h3>
              <p className="text-muted-foreground mt-1 mb-4">Generate your first partner verification code</p>
              <Button onClick={handleGenerate} variant="outline">Generate Code</Button>
            </div>
          ) : (
            <div className="relative w-full overflow-auto">
              <table className="w-full caption-bottom text-sm">
                <thead className="[&_tr]:border-b">
                  <tr className="border-b transition-colors hover:bg-muted/50 data-[state=selected]:bg-muted">
                    <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Code</th>
                    <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Status</th>
                    <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Used By</th>
                    <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground">Generated At</th>
                    <th className="h-12 px-4 text-left align-middle font-medium text-muted-foreground text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="[&_tr:last-child]:border-0">
                  {codes.map((code) => (
                    <tr key={code.id} className="border-b transition-colors hover:bg-muted/50">
                      <td className="p-4 align-middle">
                        <div className="flex items-center space-x-2">
                          <code className="relative rounded bg-muted px-[0.3rem] py-[0.2rem] font-mono text-sm font-semibold">
                            {code.code}
                          </code>
                          <Button 
                            variant="ghost" 
                            size="icon" 
                            className="h-6 w-6" 
                            onClick={() => copyToClipboard(code.code)}
                            disabled={code.isUsed}
                          >
                            {copiedCode === code.code ? (
                              <Check className="h-3 w-3 text-green-500" />
                            ) : (
                              <Copy className="h-3 w-3" />
                            )}
                          </Button>
                        </div>
                      </td>
                      <td className="p-4 align-middle">
                        <Badge variant={code.isUsed ? "secondary" : "default"} className={!code.isUsed ? "bg-green-500" : ""}>
                          {code.isUsed ? "USED" : "ACTIVE"}
                        </Badge>
                      </td>
                      <td className="p-4 align-middle text-muted-foreground">
                        {code.usedByPartnerId ? (
                          <span className="font-mono text-xs">{code.usedByPartnerId.substring(0, 12)}...</span>
                        ) : (
                          "-"
                        )}
                      </td>
                      <td className="p-4 align-middle text-muted-foreground">
                        {new Date(code.createdAt).toLocaleString()}
                      </td>
                      <td className="p-4 align-middle text-right">
                        {!code.isUsed && (
                          <Button variant="ghost" size="icon" className="text-red-500 hover:text-red-600 hover:bg-red-100 dark:hover:bg-red-900/20" onClick={() => handleDelete(code.id)}>
                            <Trash2 className="h-4 w-4" />
                          </Button>
                        )}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </CardContent>
      </Card>
    </div>
  );
}
